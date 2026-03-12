# AI Financial Advisor Setup Guide

## Overview
Your Budget_It app now includes an **AI Financial Advisor** powered by Google's Gemini API. This advisor analyzes your spending habits and provides personalized financial recommendations.

## Setup Steps

### 1. Get a Gemini API Key
1. Go to **Google AI Studio**: https://aistudio.google.com/app/apikey
2. Click **"Get API Key"** or **"Create API Key"**
3. Create a new API key (free tier available)
4. Copy the API key

### 2. Configure in Budget_It
1. Open the Budget_It app
2. Navigate to the **Wallet** screen
3. Tap the **⚙️ Settings icon** in the AI Financial Advisor card at the top
4. Paste your Gemini API key in the text field
5. Tap **"Save API Key"**
6. You'll see a ✓ confirmation

### 3. Get Financial Advice
1. Return to the Wallet screen
2. Tap **"احصل على نصائح"** (Get Advice) button
3. The AI will analyze your spending habits and provide personalized recommendations

## Features

### What the AI Advisor Analyzes:
- **Monthly Income**: Stable and variable income patterns
- **Spending Categories**: Personal use, household, transportation, entertainment, emergencies, charity
- **Budget Allocation**: Current budget distribution across categories
- **Savings & Net Credit**: Total savings and credit balance

### What You'll Get:
1. **تحليل الإنفاق** (Spending Analysis) - Key observations about your behavior
2. **فرص الادخار** (Savings Opportunities) - Where you can cut back
3. **تحسين الميزانية** (Budget Optimization) - How to rebalance allocations
4. **الصحة المالية** (Financial Health) - Overall assessment
5. **التوصيات** (Recommendations) - Actionable next steps

All advice is provided in **Arabic (العربية)** with English details where needed.

## Pricing & Limits

- **Free Tier**: 60 requests per minute (plenty for daily use)
- **No Billing Required**: Free tier is sufficient for personal use
- Get more info: https://ai.google.dev/pricing

## Security

- Your API key is stored **locally on your device** using Hive
- No data is sent to external servers except to Gemini API
- You can clear the API key anytime from the API Key Manager

## Troubleshooting

### "Invalid API key" Error
- Make sure you copied the entire key correctly
- Check that the key is active at Google AI Studio
- Try generating a new key

### "Rate limit exceeded" Error
- You've made more than 60 requests per minute
- Wait a minute before trying again
- Upgrade to a paid plan for higher limits

### "No API Key configured" Error
- Open the API Key Manager (⚙️ icon)
- Enter your Gemini API key
- The AI advisor will work after configuring

## Updating the API Key

1. Tap the **⚙️ Settings icon** in the AI Advisor card
2. Enter your new API key
3. Tap **"Update API Key"**

## Removing the API Key

1. Tap the **⚙️ Settings icon** in the AI Advisor card
2. Tap **"Clear API Key"**
3. Confirm deletion

## File Structure

**New files added:**
- `lib/services/gemini_service.dart` - Handles Gemini API communication
- `lib/screens/api_key_manager_screen.dart` - API key configuration UI
- `lib/screens/wallet.dart` - Updated with AI Advisor section

**Dependencies added:**
- `http: ^1.3.0` - For making HTTP requests to Gemini API

---

Enjoy your AI-powered financial guidance! 🤖💰
