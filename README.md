# saas-mrr-retention-dashboard
MRR &amp; cohort retention dashboard built in Tableau (BigQuery -> Tableau pipeline)
## Project Summary – What This Dashboard Really Shows

This dashboard was made to understand how our SaaS business is growing month-by-month, where the revenue is coming from, and how strong our customer retention actually is. I connected BigQuery data into Tableau and then created different views to read the full story behind our MRR numbers.

Below are the main results after analysing all charts:

### **1. Total MRR Growth**
Our Monthly Recurring Revenue is increasing very fast:
- Started around **$0.0M** early 2023  
- Reached around **$10.7M** by Jan 2025  
- Growth is consistent every single month  
- No major drop points → very healthy upward trend  

This clearly shows the business is scaling and acquiring customers continuously.

---

### **2. Monthly Revenue + Retention (Dual-Axis Trend)**
This chart compares:
- **Total MRR (bars)**
- **Net RCR % – Net Revenue Retention (red line)**

Observations:
- Net RCR (%) stays close to **0% range**, slightly negative sometimes  
- This means expansion and churn almost balance out  
- Total MRR still grows strongly → growth mostly driven by **new customers**, not expansion  

---

### **3. MRR Movement Breakdown**
This section splits revenue into:
- **New MRR**
- **Expansion MRR**
- **Contraction MRR**
- **Churn MRR**

Major findings:
- **Net New MRR** is the biggest contributor every month  
- **Expansion MRR** grows slowly but steady  
- **Churn MRR spikes in some months** (especially year-end), something to watch  
- Overall movement is positive, showing the business is adding more value than it loses  

---

### **4. Plan-Tier Segmentation**
Revenue distribution by customer plans:
- **Pro plan = $53.40M** → this is the main revenue engine  
- **Enterprise = $9.58M**  
- **Basic = $0.30M**  
- Unknown plan almost zero  

This tells us most customers are choosing higher-value plans.

---

### **5. Country Segmentation**
MRR contribution by geography:
- US & Canada are the strongest markets  
- India and Australia show good but smaller numbers  
- Some regions have almost no presence → which means potential expansion zones  

---

### **6. Cohort Retention — MRR Heatmap**
This part helps see how long customers stay after signup:
- Strong retention in early months (values around **50–80%**)  
- Some cohorts drop sharply after 10–12 months  
- A few months show unusually high retention (e.g., September cohort)  
- Heatmap makes it clear where churn happens and where customers stay stable  

---

### **7. Overall Business Health**
Putting all charts together:
- Revenue growth is **very strong and consistent**  
- Retention is **good**, but not perfect  
- Growth is mainly driven by **new customers**, not expansion  
- Churn exists but not enough to slow the growth curve  
- Pro plan users generate most of the income  
- US & Canada dominate revenue contribution  

In short:  
**The business is scaling fast, but long-term retention should be improved to reduce churn pressure.**
