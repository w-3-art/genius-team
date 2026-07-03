# genius-content — Templates & Checklists

Loaded on demand from `SKILL.md`. Full templates for blog posts, newsletters,
social threads, content calendar, plus the exhaustive distribution and SEO checklists.

---

## Step 1 — Content Audit & Strategy (commands + pillars)

```bash
# Read existing content strategy
cat .genius/content-strategy.md 2>/dev/null
cat .genius/state.json | grep -A10 content 2>/dev/null
ls content/ blog/ posts/ 2>/dev/null | head -20
```

**Content pillars framework (ask user to confirm):**
- **Pillar 1:** Core problem the product solves (educational)
- **Pillar 2:** Industry insights & trends (thought leadership)
- **Pillar 3:** Product/feature deep-dives (product marketing)
- **Pillar 4:** Customer stories (social proof)

---

## Step 2 — Blog Post Structure (full template)

```markdown
---
title: "How to [Achieve Outcome] with [Tool/Method]: A [Adjective] Guide"
description: "One sentence summary with primary keyword. Under 160 chars."
publishedAt: "2026-03-10"
author: "Name"
tags: ["keyword1", "keyword2"]
---

## Hook (first 150 words — CRITICAL)

Open with:
- A surprising statistic
- A relatable problem
- A contrarian take
- A direct question

**Example:** "83% of developers report their documentation is out of date.
Here's why — and the 3-hour fix we use at [Company]."

---

## The Problem (establish pain)

Describe the problem in detail. Make the reader feel seen.

## Why Existing Solutions Fail

Briefly address why common approaches don't work.

## The Solution

### Step 1 — [Action]
### Step 2 — [Action]
### Step 3 — [Action]

## Real-World Example

Case study or example with specific numbers.

## Key Takeaways

- Takeaway 1
- Takeaway 2
- Takeaway 3

## Next Steps

**CTA:** [One specific action to take]
```

**SEO checklist (quick):**
- [ ] Primary keyword in title, first paragraph, one H2
- [ ] Meta description under 160 chars with keyword
- [ ] 3-5 internal links to related posts
- [ ] At least one external link to authoritative source
- [ ] Images have descriptive alt text
- [ ] Post length: 1,200–2,500 words for informational, 500–800 for news

---

## Step 3 — Newsletter Format (full template)

```markdown
Subject line: [Benefit/Curiosity gap] — keep under 50 chars
Preview/Preheader: Expand on subject, don't repeat it

---

Hi {first_name},

**[Hook — 1-2 sentences]**

[Main content — 150-300 words max]

**[Callout box or key insight]**

[Secondary section if needed — keep it tight]

---

🔗 **This week's link:** [One resource worth sharing]

[CTA button — one action]

---
Until next week,
[Name]

P.S. [Optional: personal note, additional CTA, or teaser for next issue]
```

**Subject line A/B test formulas:**
- **A (curiosity):** "The mistake 90% of founders make with pricing"
- **B (direct value):** "How to set SaaS prices that don't scare customers away"

**Segmentation hooks:**
- Onboarding sequence (Days 1, 3, 7, 14, 30)
- Feature announcement (segment by plan tier)
- Re-engagement (90 days inactive)

---

## Step 4 — Social Media Threads (full structures)

**Hook-Body-CTA pattern:**

```markdown
## X/Twitter Thread Structure

[Tweet 1 — HOOK]
Strong opener. Bold claim or surprising fact.
Don't end with a question. Just make them want to read on.

[Tweet 2-3 — Problem]
Establish why this matters. Make it relatable.

[Tweet 4-7 — Solution/Content]
The actual value. Use numbers. Be specific.

[Tweet 8 — Summary]
"Here's the TL;DR:"
• Point 1
• Point 2
• Point 3

[Tweet 9 — CTA]
If this was useful, [follow/RT/reply].
[Link to full article/product]
```

```markdown
## LinkedIn Post Structure

[Hook — first line before "...see more" cutoff — 150 chars max]
Make it provocative, surprising, or vulnerable.

[Line break — essential on LinkedIn]

[Body — 3-5 short paragraphs, max 3 lines each]
Use white space liberally.

Specific > general.
Numbers > adjectives.

[Line break]

[Takeaway — the one thing to remember]

[CTA — question or action]

[Hashtags — 3-5, at the end, relevant]
#SaaS #ProductManagement #Startup
```

---

## Step 5 — Content Calendar (full template)

```markdown
# Content Calendar — Q2 2026

## Publishing Cadence
- Blog: 2x/week (Tuesday + Thursday)
- Newsletter: Weekly (Wednesday)
- LinkedIn: 3x/week
- X/Twitter: Daily

## Week 1 (March 10-14)
- Blog: "How we cut churn by 40% in 90 days" (case study)
- Newsletter: Launch edition — what's new + roadmap preview
- LinkedIn: Thread on the churn metric data
- X: 10-tweet breakdown of our pricing model

## Evergreen Content Queue
- [ ] "Ultimate guide to [core problem]" — pillar page
- [ ] "[Tool] vs [Tool]: honest comparison" — competitor keyword
- [ ] "How we built X" — build-in-public
- [ ] Customer success story
```

---

## Step 6 — Content Distribution Checklist (full)

After publishing, distribute across channels:

```markdown
## Distribution Checklist

### Owned
- [ ] Published on blog with correct meta tags
- [ ] Added to email newsletter (this week's or standalone)
- [ ] Shared in product app (in-app notification or banner)

### Social
- [ ] Twitter/X thread (best time: 8-10am or 5-6pm audience timezone)
- [ ] LinkedIn post (best time: Tuesday-Thursday 8am-10am)
- [ ] Repurposed for Instagram/TikTok if visual content

### Community
- [ ] Relevant Slack/Discord communities (add value, no spam)
- [ ] Hacker News (Show HN for product launches, Ask HN for questions)
- [ ] Reddit (relevant subreddit — be a member first)
- [ ] Product Hunt (for major launches)

### SEO
- [ ] Submit URL to Google Search Console
- [ ] Build 2-3 internal links from existing posts
```

---

## Step 7 — SEO-Optimized Content Checklist (full)

Use this before publishing any long-form piece, landing article, or case study:

- [ ] Search intent is explicit: informational, comparison, transactional, or branded
- [ ] Primary keyword appears in title, slug, meta description, H1, intro, and one subheading
- [ ] Secondary keywords and related entities appear naturally without stuffing
- [ ] Title tag is compelling and stays within typical SERP truncation limits
- [ ] Meta description is specific, benefit-led, and under ~160 characters
- [ ] URL slug is short, readable, and avoids dates unless recency matters
- [ ] Opening section answers the core query quickly for featured snippets and AI summaries
- [ ] Headings are hierarchical and scannable, with sections that can stand alone in search results
- [ ] Internal links point to product pages, related posts, and one deeper authority page
- [ ] External citations point to primary or authoritative sources
- [ ] Images include descriptive filenames, alt text, and surrounding context
- [ ] FAQ, how-to steps, comparison tables, or original data are included when they improve search coverage
- [ ] Schema markup needs are identified: `Article`, `FAQPage`, `HowTo`, or `BreadcrumbList`
- [ ] Author, publish date, and last updated date are present for trust and freshness signals
- [ ] CTA matches the query intent instead of interrupting the informational flow too early
- [ ] GEO signals are present: quotable insights, crisp definitions, and source-backed claims AI tools can cite
