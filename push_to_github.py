import os
import subprocess
import getpass

def main():
    print("===========================================")
    print("🚀 GITHUB PUSH ASSISTANT")
    print("===========================================")
    print("Since GitHub requires a Personal Access Token (PAT) instead of a password,")
    print("this script will help you push your code safely.")
    print("Get your token here: https://github.com/settings/tokens")
    print("===========================================\n")
    
    username = input("Enter your GitHub username: ").strip()
    if not username:
        print("Username is required. Exiting.")
        return

    token = getpass.getpass("Enter your Personal Access Token (input will be hidden): ").strip()
    if not token:
        print("Token is required. Exiting.")
        return

    # Set up the secure URL
    repo_url = f"https://{username}:{token}@github.com/SRISHTI-HACKATHON-2026/team-112.git"

    print("\nPushing to GitHub...")
    
    try:
        # Push using the authenticated URL
        result = subprocess.run(
            ["git", "push", "-u", repo_url, "main"],
            check=True,
            capture_output=True,
            text=True
        )
        print("✅ Success! Your code has been pushed to team-112.")
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print("❌ Failed to push to GitHub. Make sure your token is correct and has 'repo' permissions.")
        print(e.stderr)

if __name__ == "__main__":
    main()
