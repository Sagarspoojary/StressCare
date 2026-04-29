from pymongo import MongoClient
import os
import dns.resolver
from dotenv import load_dotenv

load_dotenv()

# Force Google DNS to bypass local network blocking
dns.resolver.default_resolver = dns.resolver.Resolver(configure=False)
dns.resolver.default_resolver.nameservers = ['8.8.8.8', '8.8.4.4']

MONGO_URI = os.getenv("MONGO_URI")

client = MongoClient(MONGO_URI)

# ✅ use same DB name everywhere
db = client["stress_care"]