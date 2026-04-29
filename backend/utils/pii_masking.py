import re

def mask_pii(text: str) -> str:
    """
    Remove or hide personal information like phone numbers or email addresses.
    """
    masked = text
    
    # Mask email addresses
    email_pattern = r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
    masked = re.sub(email_pattern, '[EMAIL]', masked)
    
    # Mask phone numbers (various formats)
    phone_patterns = [
        r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b',  # 123-456-7890
        r'\b\d{10}\b',                          # 1234567890
        r'\b\+\d{1,3}[-.\s]?\d{1,14}\b',       # +1-234-567-8900
        r'\b\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b',  # (123) 456-7890
    ]
    
    for pattern in phone_patterns:
        masked = re.sub(pattern, '[PHONE]', masked)
    
    # Mask URLs
    url_pattern = r'https?://[^\s]+'
    masked = re.sub(url_pattern, '[URL]', masked)
    
    # Mask credit card numbers (basic)
    cc_pattern = r'\b\d{4}[-.\s]?\d{4}[-.\s]?\d{4}[-.\s]?\d{4}\b'
    masked = re.sub(cc_pattern, '[CARD]', masked)
    
    # Mask Aadhaar (Indian ID) - 12 digits
    aadhaar_pattern = r'\b\d{12}\b'
    masked = re.sub(aadhaar_pattern, '[AADHAAR]', masked)
    
    return masked