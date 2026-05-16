# Multivariate Academy Award Prediction: Modeling the Best Picture Oscar
An End-to-End Predictive and Statistical Framework Analyzing 21st-Century Nominees

## Problem Statement
The Academy Award for Best Picture is the film industry's most prestigious honor. While annual media speculation surrounding the awards is intense, most commercial predictions remain entirely subjective. This project moves beyond subjective reporting by using rigorous multivariate statistical modeling to identify the objective technical, institutional, and audience factors that differentiate actual Oscar winners from fellow nominees.

The primary analytical challenge is parsing high-dimensional data while controlling for intense confounding variables (such as a director's historical legacy or studio financial sheets) and avoiding structural look-ahead bias. By uncovering these underlying criteria, this repository establishes a statistically validated blueprint of how cinematic elements resonate with the voting body of the Academy.

## Methodology
To ensure high-fidelity inputs and clean statistical boundaries, the analytical pipeline followed these core phases:

(1) Granular Web Scraping & Data Pipeline: 
Extracted structural text files from the official Oscar Database. Programmatically gathered metadata (budgets, runtimes) from Wikipedia via R, historical tracking from the Golden Globe Database, and public sentiment profiles (Tomatometer/Popcornmeter) by crafting a custom URL slug override script for Rotten Tomatoes.  

(2) Visual Cue Extractions: 
Solved data-labeling omissions using programmatic visual parsing in R. Extracted Oscar winners by querying the presence of the span.glyphicon-star HTML class, and extracted Golden Globe winners by filtering lines for the specific Light Steel Blue hex code highlights (#B0C4DE) inside Wikipedia tables.  

(3) Time-Aligned History Accumulation: 
Built a dual-layered accumulation matrix ("before" vs. "include_now") to track a director's career momentum. This explicitly bounds historical tallies to the concurrent ceremony year, preventing future career wins from causing look-ahead bias in past prediction folds.  

(4) Categorical Matrix Condensation: Mitigated high-dimensional sparsity by running a one-hot tokenization script on raw movie strings. Consolidated 21 complex genres into 5 broad thematic groupings (Drama, Human Interest, Suspense, Entertainment, and Niche) and collapsed low-sample MPAA rows into a single PG and under bin.  

(5) Structural Interaction Checks: Employed the Likelihood Ratio Test to check multi-way interaction models, discovering a major structural shift before and after the Academy's 2009 expansion to a 10-nominee preferential voting system.  

## Dataset Overview
Dataset OverviewThe finalized database, academy_final.csv, contains 201 unique film observations spanning the 72nd (2000) through 98th (2025) Academy Awards. The underlying matrix features 45 predictors and 1 binary response variable (best_picture_winner).  

Features track:
- Acclaim & Industry Precursors: Best Film Editing nomination/win flags, Best Director current and historical wins, total non-Best Picture Oscar wins, and Golden Globe tallies.
- Reception Sentiment: Tomatometer (Critics) and Popcornmeter (Audience) percentages.
- Production Metadata: Year-normalized budget/box office tiers, runtime minutes, title character length, and language indicators.  

## Exploratory Data Analysis (EDA) & Uncertainty Framework
Before fitting predictive structures, we ran exhaustive distribution and correlation analyses to evaluate the isolated strength of our features. 

To prevent false assumptions about our dataset, we deployed a rigorous mathematical framework to handle categorical and non-normal variables:  

(1) Wilson Score Interval: 
For binary proportions and winning rates, we utilized the Wilson Score interval over the standard Wald approximation. This mathematical choice handles rare categorical splits safely, preventing "impossible" negative bounds and recognizing that even if a sub-category has zero wins in our sample, its true underlying win probability remains non-zero.  

(2) Non-Parametric Bootstrapping: 
For highly skewed, non-binary variables (such as raw financial sheets and award tallies), standard normal-theory metrics fail. We repeatedly resampled the data with replacement to build empirical sampling distributions, deriving our 95% confidence intervals directly from observed percentiles to realistically capture uncertainty.  

### Key Cinematic Findings:

(1) The Volume Illusion of Drama:
At a glance, the Drama genre dominates the raw winner counts. However, converting these counts to proportions reveals that Mystery/Thriller, Crime, and Adventure actually secure a higher win rate per submission. When computing the 95% Wilson Score intervals, the massive overlap and wide error bars reveal that genre alone is not a statistically distinct indicator of success.  

![Drama Genre](Drama_Genre.png)

![Drama Genre Significance](Drama_Genre_Significance.png)

(2) Negligible Language Variance: 
The vast majority of nominated and winning films are strictly English-language productions. Because only two non-English titles won Best Picture within our sample timeframe, the language variable provides zero practical predictive information for the final model.  

![Language](Language.png)

(3) The Maturity Trend: 
Mosaic plot visualization demonstrates that Best Picture win rates scale upward as content restrictions become more mature, with R and PG-13 films getting selected far more frequently than G or PG entries. Even so, strict Wilson intervals overlap heavily, rendering MPAA rating mathematically insignificant on its own.  

![Rating](Rating.png)

(4) Streaming Disruption & Box Office Decay: 
Tracking revenue longitudinally exposes a steady decline in average box office returns for nominated titles over the 21st century—a shift tracking the erosion of the traditional theatrical window by major streaming services.  

![Box Office](Box_Office.png)

(5) The Audience-Critic Misalignment: 
Mapping critical scores displays a dense clustering of both winners and losers in the top-right quadrant, implying that high critic acclaim is a baseline requirement to be nominated rather than an isolated driver of a win. Interestingly, the audience-driven Popcornmeter score showed a more visible statistical separation between winners and non-winners compared to the professional Tomatometer score. 

(6) Craft Excellence (The Sweep Effect): 
Broad institutional support across creative departments is the single strongest indicator of voter consensus. The average total awards won (excluding Best Picture itself) are substantially higher for winners than non-winners. This difference is highly statistically significant, as backed by completely non-overlapping 95% bootstrapped confidence intervals.  

(7) The Best Film Editing Prerequisite: 
Technical validation from editing peers acts as a crucial, reliable gatekeeper for a film's overall victory. Films nominated for or winning Best Film Editing see a sharp, step-wise surge in their Best Picture win rates, peaking at 45.5% for editing winners. This structural climb is verified by perfectly non-overlapping 95% Wilson Score intervals.  

(8) Directorial Momentum vs. Past Pedigree: While a director's historical legacy or past nominations offer no statistical separation or predictive advantage once a film is nominated, current-year momentum is incredibly powerful. Winning Best Director at the concurrent ceremony yields a powerful statistical signal, corresponding to a 33.3% Best Picture win probability within the sample.

### Correlation Plot

![Correlation](Correlation.png)

### Inference from EDA

![Guess](Guess.png)

For detailed visuals, analysis, and explanation, please refer to our deck or report. 













