def analyze_user_history(history):
    """
    Input: last N messages (list of dicts with emotion, burnout_score, created_at)
    Output: pattern_summary dict
    """
    if not history:
        return {
            "repeated_pattern": False,
            "increasing_stress": False,
            "high_risk": False,
            "fatigue_cycle": False
        }

    # Extract data for easier analysis
    emotions = [h.get("emotion") for h in history if h.get("emotion")]
    scores = [h.get("score") or h.get("burnout_score") or 0 for h in history]
    
    # 🔁 Repeated Emotion Pattern
    # Check if any emotion (except neutral) appears 3+ times in recent history
    repeated_pattern = False
    from collections import Counter
    counts = Counter(emotions)
    for emo, count in counts.items():
        if emo != "neutral" and count >= 3:
            repeated_pattern = True
            break
            
    # 📈 Stress Trend
    # If burnout_score is generally increasing over last 3-5 messages
    increasing_stress = False
    if len(scores) >= 3:
        # Simple check: is latest score higher than average of previous?
        latest = scores[0] # history is sorted -1 (latest first)
        prev_avg = sum(scores[1:4]) / len(scores[1:4]) if len(scores) > 1 else 0
        if latest > prev_avg + 15: # Significant increase
            increasing_stress = True
            
    # ⚠️ High Risk
    # If burnout_score > 70 multiple times (at least 2)
    high_risk_count = sum(1 for s in scores if s > 70)
    high_risk = high_risk_count >= 2
    
    # 😴 Fatigue Cycle
    # If "fatigue" appears frequently (at least 3 times)
    fatigue_cycle = counts.get("fatigue", 0) >= 3
    
    result = {
        "repeated_pattern": repeated_pattern,
        "increasing_stress": increasing_stress,
        "high_risk": high_risk,
        "fatigue_cycle": fatigue_cycle
    }
    
    return result
