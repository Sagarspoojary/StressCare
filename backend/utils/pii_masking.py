import re
import logging
import difflib

try:
    import spacy
    nlp = spacy.load("en_core_web_sm")
except Exception as e:
    nlp = None
    logging.warning(f"spaCy not available or model not downloaded: {e}")

# --- PRECOMPILED PATTERNS & CONSTANTS ---
EMAIL_PATTERN = re.compile(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}')
AADHAAR_PATTERN = re.compile(r'\b\d{4}\s?\d{4}\s?\d{4}\b')
PHONE_PATTERN = re.compile(r'(?<!\d)(?:\d[\s-]*){9}\d(?!\d)')
PAN_PATTERN = re.compile(r'\b[A-Z]{5}[0-9]{4}[A-Z]{1}\b')
CREDIT_CARD_PATTERN = re.compile(r'\b(?:\d[ -]*?){13,16}\b')
IFSC_PATTERN = re.compile(r'\b[A-Z]{4}0[A-Z0-9]{6}\b')
BANK_ACC_PATTERN = re.compile(r'(?i)\b(?:a/c|account|acct|acc)[\s:]*#?\s*(\d{9,18})\b')
PASSWORD_PATTERN = re.compile(r'(?i)\b(?:password|pass|pwd|pin)[\s:]+([^\s]+)')
GENDER_PATTERN = re.compile(r'(?i)\b(male|female|boy|girl|man|woman)\b')

NAME_CONTEXT_PATTERNS = [
    re.compile(r'(?i)\b(?:i am|i\'m|my name is|myself|my self|this is|call me|my friend|my colleague|my brother|my sister)\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{2,})\b'),
    re.compile(r'मेरा नाम\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{2,})'),
    re.compile(r'मैं\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{2,})\s+(?:हूँ|हुँ|हूं)'),
    re.compile(r'ನನ್ನ ಹೆಸರು\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{2,})'),
    re.compile(r'ನಾನು\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{2,})\s+(?:ಇದ್ದೇನೆ|ಆಗಿದ್ದೇನೆ)')
]

LOC_CONTEXT_PATTERNS = [
    re.compile(r'(?i)\b(?:i live in|i am from|based in|from|in|at)\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{3,})\b'),
    re.compile(r'मैं\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{3,})\s*(?:से|में)'),
    re.compile(r'ನಾನು\s+([A-Za-z\u0900-\u097F\u0C80-\u0CFF]{3,})\s*(?:ಇಂದ|ನಲ್ಲಿ)')
]

FILLER_WORDS = [re.compile(p, re.I) for p in [r'\bum\b', r'\buh\b', r'\buhm\b', r'\bah\b', r'\ber\b']]
REPEAT_PATTERN = re.compile(r'\b(\w+(?:[ \t]+\w+){0,3})(?:[ \t]+\1\b)+', re.I)
PUNCT_SPACING = re.compile(r'\s+([.,?!])')
WORD_EXTRACTOR = re.compile(r'\b[A-Za-z\u0900-\u097F\u0C80-\u0CFF]{3,}\b')

# Note: Regional normalization removed to preserve original language as per requirements

PREDEFINED_CITIES = {
    "bangalore", "bengaluru", "banglore", "mysore", "mysuru", "delhi", "mumbai", "chennai", "kolkata",
    "hyderabad", "pune", "ahmedabad", "jaipur", "surat", "lucknow", "kanpur", "nagpur", "indore", 
    "thane", "bhopal", "visakhapatnam", "patna", "vadodara", "ghaziabad", "ludhiana", "agra", 
    "nashik", "faridabad", "meerut", "rajkot", "varanasi", "srinagar", "aurangabad", "dhanbad", 
    "amritsar", "allahabad", "ranchi", "gwalior", "jabalpur", "coimbatore", "vijayawada", 
    "jodhpur", "madurai", "raipur", "kota", "guwahati", "chandigarh", "gurgaon", "noida"
}

PREDEFINED_NAMES = {
    "sagar", "rahul", "amit", "rohit", "sneha", "pooja", "priya", "karan", "vikas", 
    "mahesh", "suresh", "ramesh", "arjun", "neha", "anjali", "sunil", "anil", "ravi",
    "kavita", "vijay", "ajay", "sanjay", "deepak", "manish", "nitin", "alok", "divya"
}

STOPWORDS = {
    "sorry", "anxious", "sad", "happy", "angry", "tired", "depressed", "stressed", "feeling",
    "a", "an", "the", "not", "very", "so", "just", "here", "there", "now", "currently", 
    "doing", "okay", "fine", "from", "in", "at", "on", "to", "for", "with", "about", 
    "like", "sure", "glad", "good", "bad", "great", "well", "done", "going", "getting",
    "my", "your", "this", "that", "it", "is", "am", "are", "was", "were", "and", "or", "i", "m"
}

RESERVED_PREFIXES = ("USER_", "CITY_", "EMAIL_", "PHONE_", "AADHAAR_", "PAN_", "ENTITY_", "GENDER_")

class PrivacyMasker:
    def __init__(self):
        self.mapping = {} # Token -> Original
        self.reverse_mapping = {} # Original -> Token
        self.counters = {
            "USER": 1, "PHONE": 1, "EMAIL": 1, "AADHAAR": 1, 
            "PAN": 1, "CITY": 1, "ENTITY": 1, "GENDER": 1,
            "CREDITCARD": 1, "BANK": 1, "IFSC": 1, "PASSWORD": 1
        }

    def _get_token(self, entity_type: str, val: str) -> str:
        val_key = val.strip().lower()
        key = f"{entity_type}:{val_key}"
        
        if key in self.reverse_mapping:
            return self.reverse_mapping[key]
            
        token = f"{entity_type}_{self.counters[entity_type]}"
        self.counters[entity_type] += 1
        
        self.mapping[token] = val
        self.reverse_mapping[key] = token
        return token

    def _clean_text(self, text: str) -> str:
        # ASR cleaning & Normalization
        current_text = text
        for filler in FILLER_WORDS:
            current_text = filler.sub('', current_text)
        
        current_text = re.sub(r'\s{2,}', ' ', current_text).strip()
        
        # Deduplicate repeats (e.g. "I am I am")
        for _ in range(2):
            current_text = REPEAT_PATTERN.sub(r'\1', current_text)
            
        # Regional normalization removed to preserve original language
            
        return PUNCT_SPACING.sub(r'\1', current_text).strip()

    def mask(self, text: str) -> str:
        current_text = self._clean_text(text)
        
        # 1. Collect all potential entities to mask in one scan where possible
        entities = [] # List of (type, original_val)

        # Regex patterns scan
        for match in EMAIL_PATTERN.finditer(current_text):
            entities.append(("EMAIL", match.group()))
        for match in AADHAAR_PATTERN.finditer(current_text):
            entities.append(("AADHAAR", match.group()))
        for match in PHONE_PATTERN.finditer(current_text):
            entities.append(("PHONE", match.group()))
        for match in PAN_PATTERN.finditer(current_text):
            entities.append(("PAN", match.group()))
        for match in CREDIT_CARD_PATTERN.finditer(current_text):
            entities.append(("CREDITCARD", match.group()))
        for match in IFSC_PATTERN.finditer(current_text):
            entities.append(("IFSC", match.group()))
        for match in BANK_ACC_PATTERN.finditer(current_text):
            entities.append(("BANK", match.group(1))) # Group 1 is the actual number
        for match in PASSWORD_PATTERN.finditer(current_text):
            entities.append(("PASSWORD", match.group(1))) # Group 1 is the actual password
        for match in GENDER_PATTERN.finditer(current_text):
            entities.append(("GENDER", match.group()))

        # Context heuristics scan
        for p in NAME_CONTEXT_PATTERNS:
            for match in p.finditer(current_text):
                val = match.group(1)
                if val.lower() not in STOPWORDS and not val.startswith(RESERVED_PREFIXES):
                    entities.append(("USER", val))

        for p in LOC_CONTEXT_PATTERNS:
            for match in p.finditer(current_text):
                val = match.group(1)
                if val.lower() not in STOPWORDS and not val.startswith(RESERVED_PREFIXES):
                    entities.append(("CITY", val))

        # NLP Scan (One pass)
        if nlp:
            doc = nlp(current_text)
            for ent in doc.ents:
                if ent.text.startswith(RESERVED_PREFIXES): continue
                if ent.label_ == "PERSON":
                    entities.append(("USER", ent.text))
                elif ent.label_ in ["GPE", "LOC", "FAC"]:
                    entities.append(("CITY", ent.text))
                elif ent.label_ in ["ORG", "PRODUCT", "WORK_OF_ART", "EVENT"]:
                    entities.append(("ENTITY", ent.text))

        # Dictionary & Fuzzy scan
        words = WORD_EXTRACTOR.findall(current_text)
        for word in words:
            w_lower = word.lower()
            if w_lower in STOPWORDS or word.startswith(RESERVED_PREFIXES): continue
            
            if w_lower in PREDEFINED_CITIES or difflib.get_close_matches(w_lower, PREDEFINED_CITIES, n=1, cutoff=0.9):
                entities.append(("CITY", word))
            elif w_lower in PREDEFINED_NAMES or difflib.get_close_matches(w_lower, PREDEFINED_NAMES, n=1, cutoff=0.9):
                entities.append(("USER", word))

        # 2. Sort entities by length descending to prevent partial masking (e.g. "Bangalore" vs "Bang")
        # and ensure consistent assignment by using original value as secondary sort key
        unique_entities = []
        seen = set()
        for t, v in entities:
            if (t, v) not in seen:
                unique_entities.append((t, v))
                seen.add((t, v))
        
        unique_entities.sort(key=lambda x: (len(x[1]), x[1]), reverse=True)

        # 3. Apply masking in a single pass over the sorted entity list
        for ent_type, val in unique_entities:
            token = self._get_token(ent_type, val)
            # For non-ASCII characters, \b can be unreliable in Python's re module.
            # We use lookarounds to ensure we are matching a whole word or a word at the boundary.
            # This handles punctuation like commas and suffixes in regional languages.
            escaped_val = re.escape(val)
            pattern = fr'(?<![A-Za-z\u0900-\u097F\u0C80-\u0CFF]){escaped_val}(?![A-Za-z\u0900-\u097F\u0C80-\u0CFF])'
            current_text = re.sub(pattern, token, current_text)

        return current_text

def mask_pii(text: str) -> str:
    masker = PrivacyMasker()
    return masker.mask(text)