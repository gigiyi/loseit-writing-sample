# Seeking and Receiving Support in r/loseit: Replication Files

Code and data for the writing sample *"Seeking and Receiving Support in an Online Weight-Loss Community: A Content Analysis of r/loseit"* by Yi Gao (University of Washington).

The script reproduces every statistic reported in the paper, including Tables 2 to 6.

## Files

| File | Contents |
|---|---|
| `loseit_analysis.R` | Full analysis, organized by paper section |
| `data/loseit_raw_data.csv` | 3,020 top-level comments from 20 r/loseit posts (one row per comment) |
| `data/loseit_coding.csv` | Human and ChatGPT codes for the 100 coded replies (one row per reply) |

## How to run

1. Install R (version 4.0 or later) and the `clubSandwich` package:
   ```r
   install.packages("clubSandwich")
   ```
2. Download this repository (green **Code** button > **Download ZIP**) and unzip it.
3. In R, set the working directory to the unzipped folder and run the script:
   ```r
   setwd("path/to/loseit-writing-sample")
   source("loseit_analysis.R", echo = TRUE)
   ```

The script takes about one minute. All random steps use `set.seed(570)`, so results are identical on every run.

## Data

The data were collected through the Reddit API by Professor Charles Kiene (University of Washington) for a graduate course project in spring 2026. They include the 20 posts with the most comments in r/loseit published between April 29 and May 26, 2026, and all of their top-level comments. Posts were sorted by number of comments rather than score so that each thread had enough replies to analyze.

The data contain no usernames. Comment text is included so the coding can be checked; please do not quote it in a way that could identify users.

### Main variables in `loseit_raw_data.csv`

| Variable | Description |
|---|---|
| `post_id`, `comment_id` | Reddit IDs |
| `comment_score` | Final comment score (upvotes minus downvotes) |
| `lag_hours` | Hours between the original post and the comment |
| `comment_words` | Comment length in words |
| `deleted` | 1 = deleted or removed (excluded from analysis) |

### Codes in `loseit_coding.csv`

Columns starting with `human_` are the author's codes; columns starting with `gpt_` are ChatGPT's codes. For post-level variables, `_a` and `_b` are the first and second human codes. Posts where they differ were treated as ambiguous.

| Variable | Codes |
|---|---|
| P1 Post type | 1 vent, 2 advice-seeking, 3 knowledge-sharing, 4 milestone, 5 commentary, 6 humor |
| C1 Reply function | 1 validation, 2 experience, 3 advice, 4 humor, 5 challenge, 6 mixed |
| C3 Reply tone | 1 supportive, 2 neutral, 3 critical |

The full codebook (P1 to P6 and C1 to C3) is in Table 1 of the paper.

## Key results

| Result | Estimate | 95% CI |
|---|---|---|
| Commentary posts: experience replies (difference, pp) | 42.1 | [3.5, 65.0] |
| Advice-seeking posts: advice replies (difference, pp) | 28.1 | [-1.7, 60.6] |
| Vent posts: validation replies (difference, pp) | 18.5 | [-1.2, 37.2] |
| Leave-one-post-out range, commentary result (pp) | 37.1 to 57.1 | |
| Posting time score multiplier (per doubling) | 0.69 | [0.65, 0.73] |
| Comment length score multiplier (per doubling) | 1.04 | [0.99, 1.08] |
| P(score > 1), posted at 1 hour vs. 12 hours | 66.8% vs. 31.8% | difference [27.8, 42.9] |
| Matching vs. other top replies (score ratio) | 0.97 | [0.56, 1.68] |
| Human-ChatGPT agreement, reply function (kappa) | .63 | |

Percentage-point differences use 4,000 post-level bootstrap resamples. Regression intervals use CR2 cluster-robust standard errors clustered by post (Pustejovsky & Tipton, 2018).
