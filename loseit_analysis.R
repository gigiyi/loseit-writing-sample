# COM 570 Writing Sample: r/loseit analysis
# Yi Gao
#
# Data files (in the data folder):
#   loseit_raw_data.csv  - all top-level comments from 20 posts
#   loseit_coding.csv    - the 100 coded replies (human and ChatGPT codes)
#
# Codes used in loseit_coding.csv
#   P1 (post type):      1 vent, 2 advice-seeking, 3 knowledge-sharing,
#                        4 milestone, 5 commentary, 6 humor
#   C1 (reply function): 1 validation, 2 experience, 3 advice,
#                        4 humor, 5 challenge, 6 mixed
#   C3 (reply tone):     1 supportive, 2 neutral, 3 critical
#
# How to run:
#   1. Set the working directory to this repository folder, e.g.
#      setwd("~/Downloads/loseit-writing-sample")
#      (In RStudio: Session > Set Working Directory > Choose Directory)
#   2. Run the whole script: source("loseit_analysis.R", echo = TRUE)
#   The full script takes about one minute. Expected results are in README.md.

# install.packages("clubSandwich")   # run once
library(clubSandwich)

loseit <- read.csv("data/loseit_raw_data.csv")
coded  <- read.csv("data/loseit_coding.csv")


#### 1. Sample ####

nrow(loseit)                      # 3,020 comments
length(unique(loseit$post_id))    # 20 posts
sum(loseit$deleted == 1)          # 63 deleted or removed

comments <- loseit[loseit$deleted == 0, ]
nrow(comments)                    # 2,957 usable comments

# Two posts had different first and second human codes for post type.
# They are left out of the post-type comparisons.
unclear <- unique(coded$post_id[coded$human_P1_a != coded$human_P1_b])
unclear
clear <- coded[!coded$post_id %in% unclear, ]
nrow(clear)                       # 90 replies
length(unique(clear$post_id))     # 18 posts


#### 2. Reply function by post type (Tables 2 and 3) ####

# Number of posts of each type
posts <- clear[!duplicated(clear$post_id), ]
table(posts$human_P1_a)

# Reply functions under each post type (column percentages)
round(prop.table(table(clear$human_C1, clear$human_P1_a), 2) * 100, 1)

# Difference in percentage points:
# share of a reply function under one post type
# minus its share under all other post types
pct_diff <- function(data, type_var, reply_var, type, reply) {
  target <- data[data[[type_var]] == type, ]
  other  <- data[data[[type_var]] != type, ]
  (mean(target[[reply_var]] == reply) - mean(other[[reply_var]] == reply)) * 100
}

# Advice-seeking posts and advice replies
mean(clear$human_C1[clear$human_P1_a == 2] == 3) * 100   # 37.1
mean(clear$human_C1[clear$human_P1_a != 2] == 3) * 100   # 9.1
pct_diff(clear, "human_P1_a", "human_C1", 2, 3)          # 28.1

# Vent posts and validation replies
mean(clear$human_C1[clear$human_P1_a == 1] == 1) * 100   # 20.0
mean(clear$human_C1[clear$human_P1_a != 1] == 1) * 100   # 1.5
pct_diff(clear, "human_P1_a", "human_C1", 1, 1)          # 18.5

# Commentary posts and experience replies
mean(clear$human_C1[clear$human_P1_a == 5] == 2) * 100   # 65.0
mean(clear$human_C1[clear$human_P1_a != 5] == 2) * 100   # 22.9
pct_diff(clear, "human_P1_a", "human_C1", 5, 2)          # 42.1


# Bootstrap confidence intervals.
# The five replies from one post are not independent, so whole posts
# are resampled. A resample with no post of the target type is skipped.
boot_diff <- function(data, type_var, reply_var, type, reply) {
  set.seed(570)
  post_list <- unique(data$post_id)
  rows <- split(1:nrow(data), data$post_id)
  diffs <- rep(NA, 4000)
  for (i in 1:4000) {
    pick <- sample(post_list, replace = TRUE)
    resample <- data[unlist(rows[pick]), ]
    diffs[i] <- pct_diff(resample, type_var, reply_var, type, reply)
  }
  cat("skipped resamples:", sum(is.na(diffs)), "\n")
  quantile(diffs, c(.025, .975), na.rm = TRUE)
}

boot_diff(clear, "human_P1_a", "human_C1", 2, 3)   # advice:     [-1.7, 60.6]
boot_diff(clear, "human_P1_a", "human_C1", 1, 1)   # validation: [-1.2, 37.2]
boot_diff(clear, "human_P1_a", "human_C1", 5, 2)   # experience: [3.5, 65.0]


# Leave-one-post-out check for the commentary result:
# drop one post at a time and compute the difference again
post_list <- unique(clear$post_id)
loo <- rep(NA, length(post_list))
for (i in 1:length(post_list)) {
  without <- clear[clear$post_id != post_list[i], ]
  loo[i] <- pct_diff(without, "human_P1_a", "human_C1", 5, 2)
}
names(loo) <- post_list
round(loo, 1)
range(loo)                                          # 37.1 to 57.1


#### 3. Supportive tone (Table 4) ####

# Reply function by tone, all 100 replies
table(coded$human_C1, coded$human_C3)

# Share of supportive replies under each post type
round(tapply(clear$human_C3 == 1, clear$human_P1_a, mean) * 100, 1)

# Vent posts compared with all other post types
pct_diff(clear, "human_P1_a", "human_C3", 1, 1)    # 20.3
boot_diff(clear, "human_P1_a", "human_C3", 1, 1)   # [-25.0, 58.7]


#### 4. Posting time and comment scores (Table 5) ####

comments$score_log <- log2(pmax(comments$comment_score, 1))
comments$time_log  <- log2(comments$lag_hours + 1)
comments$words_log <- log2(comments$comment_words)

sum(comments$comment_score <= 1)                 # 1,586
mean(comments$comment_score <= 1) * 100          # 53.6
sum(comments$comment_score <= 0)                 # 197

# Coded replies compared with all other comments
comments$coded <- comments$comment_id %in% coded$comment_id
tapply(comments$lag_hours <= 1, comments$coded, mean) * 100       # 17.6, 89.0
median(comments$lag_hours[comments$coded]) * 60                   # 15.3 minutes
median(comments$lag_hours[!comments$coded])                       # 5.10 hours

early <- comments[comments$lag_hours <= 1, ]
nrow(early)                                      # 591
sum(early$comment_score <= 1)                    # 146

# Share of each thread's positive score points held by its top five replies
top_share <- rep(NA, length(unique(comments$post_id)))
i <- 1
for (p in unique(comments$post_id)) {
  scores <- comments$comment_score[comments$post_id == p]
  scores <- sort(scores[scores > 0], decreasing = TRUE)
  top_share[i] <- sum(scores[1:5]) / sum(scores)
  i <- i + 1
}
median(top_share) * 100                          # 76.0


# Linear regression with post fixed effects
model1 <- lm(score_log ~ factor(post_id), data = comments)
model2 <- lm(score_log ~ words_log + factor(post_id), data = comments)
model3 <- lm(score_log ~ time_log + words_log + factor(post_id), data = comments)
summary(model1)$r.squared                        # .045
summary(model2)$r.squared                        # .047
summary(model3)$r.squared                        # .256

summary(model3)$coef[2:3, ]

# Comments are nested in posts, so the standard errors are clustered
# by post (CR2 correction for a small number of clusters)
cr2 <- coef_test(model3, vcov = "CR2", cluster = comments$post_id,
                 test = "Satterthwaite", coefs = c("time_log", "words_log"))
cr2

# Posting time
est  <- cr2$beta[1]
se   <- cr2$SE[1]
tval <- qt(.975, cr2$df_Satt[1])
c(est, est - tval*se, est + tval*se)             # -0.536 [-0.619, -0.452]
2^c(est, est - tval*se, est + tval*se)           # 0.69 [0.65, 0.73]

# Comment length
est  <- cr2$beta[2]
se   <- cr2$SE[2]
tval <- qt(.975, cr2$df_Satt[2])
c(est, est - tval*se, est + tval*se)             # 0.051 [-0.008, 0.109]
2^c(est, est - tval*se, est + tval*se)           # 1.04 [0.99, 1.08]


# Model check: simulate 1,000 data sets from model3 and find the share
# of scores of one or below (score_log of 0 or less)
set.seed(570)
sigma <- summary(model3)$sigma
sim_share <- rep(NA, 1000)
for (i in 1:1000) {
  sim_score <- fitted(model3) + rnorm(nrow(comments), 0, sigma)
  sim_share[i] <- mean(sim_score <= 0)
}
quantile(sim_share, c(.025, .975)) * 100         # 25.3 to 28.2


# Logistic regression: chance that a comment scores above one
comments$high <- ifelse(comments$comment_score > 1, 1, 0)
logit <- glm(high ~ time_log + words_log + factor(post_id),
             data = comments, family = binomial)

# Predicted probability if every comment had been posted at a given hour,
# averaged over all comments
pred_prob <- function(model, data, hours) {
  data$time_log <- log2(hours + 1)
  mean(predict(model, newdata = data, type = "response")) * 100
}
p1  <- pred_prob(logit, comments, 1)
p12 <- pred_prob(logit, comments, 12)
c(p1, p12, p1 - p12)                             # 66.8, 31.8, 35.0

# Bootstrap the predicted probabilities by resampling whole posts.
# Each resampled post gets its own fixed effect, even if drawn twice.
set.seed(570)
post_list <- unique(comments$post_id)
rows <- split(1:nrow(comments), comments$post_id)
boot_p1  <- rep(NA, 4000)
boot_p12 <- rep(NA, 4000)
for (i in 1:4000) {
  pick <- sample(post_list, replace = TRUE)
  resample <- comments[unlist(rows[pick]), ]
  resample$boot_post <- rep(1:20, times = lengths(rows[pick]))
  fit <- suppressWarnings(glm(high ~ time_log + words_log + factor(boot_post),
                              data = resample, family = binomial))
  boot_p1[i]  <- pred_prob(fit, resample, 1)
  boot_p12[i] <- pred_prob(fit, resample, 12)
}
quantile(boot_p1, c(.025, .975))                 # [60.2, 74.1]
quantile(boot_p12, c(.025, .975))                # [25.0, 38.2]
quantile(boot_p1 - boot_p12, c(.025, .975))      # [27.8, 42.9]


#### 5. Reply function and score among the top replies ####

top <- merge(coded, loseit[, c("comment_id", "comment_score",
                               "lag_hours", "comment_words")],
             by = "comment_id")
top$score_log <- log2(pmax(top$comment_score, 1))
top$time_log  <- log2(top$lag_hours + 1)
top$words_log <- log2(top$comment_words)

# Experience replies are the comparison group
top$func <- factor(top$human_C1, levels = c(2, 1, 3, 4, 5, 6),
                   labels = c("experience", "validation", "advice",
                              "humor", "challenge", "mixed"))

model4 <- lm(score_log ~ func + time_log + words_log + factor(post_id), data = top)
cr2 <- coef_test(model4, vcov = "CR2", cluster = top$post_id,
                 test = "Satterthwaite", coefs = paste0("func", levels(top$func)[-1]))
tval <- qt(.975, cr2$df_Satt)
ratio <- data.frame(ratio = 2^cr2$beta,
                    lower = 2^(cr2$beta - tval*cr2$SE),
                    upper = 2^(cr2$beta + tval*cr2$SE))
rownames(ratio) <- levels(top$func)[-1]
round(ratio, 2)                                  # challenge 0.85 [0.39, 1.85] ... mixed 1.30 [0.61, 2.76]

# Replies that matched their post's request vs. other top replies
top_clear <- top[!top$post_id %in% unclear, ]
top_clear$match <- (top_clear$human_P1_a == 2 & top_clear$human_C1 == 3) |
                   (top_clear$human_P1_a == 1 & top_clear$human_C1 == 1) |
                   (top_clear$human_P1_a == 5 & top_clear$human_C1 == 2)
sum(top_clear$match)                             # 31 of 90

model5 <- lm(score_log ~ match + time_log + words_log + factor(post_id), data = top_clear)
cr2 <- coef_test(model5, vcov = "CR2", cluster = top_clear$post_id,
                 test = "Satterthwaite", coefs = "matchTRUE")
est  <- cr2$beta
se   <- cr2$SE
tval <- qt(.975, cr2$df_Satt)
round(2^c(est, est - tval*se, est + tval*se), 2) # 0.97 [0.56, 1.68]


#### 6. Agreement between human and ChatGPT codes (Table 6) ####

# Percentage agreement and Cohen's kappa
kappa <- function(x, y) {
  codes <- sort(union(x, y))
  tab <- table(factor(x, codes), factor(y, codes))
  agree  <- sum(diag(tab)) / sum(tab)
  chance <- sum(rowSums(tab) * colSums(tab)) / sum(tab)^2
  round(c(agreement = agree * 100, kappa = (agree - chance) / (1 - chance)), 2)
}

posts20 <- coded[!duplicated(coded$post_id), ]
kappa(posts$human_P1_a, posts$gpt_P1)       # post type, 18 posts: 94.4, .92
kappa(coded$human_C1, coded$gpt_C1)         # reply function: 71.0, .63
kappa(coded$human_C3, coded$gpt_C3)         # tone: 75.0, .56
kappa(posts20$human_P2_a, posts20$gpt_P2)   # locus: 45.0, .24
kappa(coded$human_C2, coded$gpt_C2)         # response: 45.0, .24

sum(coded$human_C1 != coded$gpt_C1)         # 29 disagreements
table(coded$gpt_C1[coded$human_C1 == 6])    # ChatGPT codes for human "mixed"

# Main comparisons repeated with ChatGPT's codes (all 20 posts)
pct_diff(coded, "gpt_P1", "gpt_C1", 2, 3)   # 24.2
boot_diff(coded, "gpt_P1", "gpt_C1", 2, 3)  # [-0.4, 48.8]
pct_diff(coded, "gpt_P1", "gpt_C1", 1, 1)   # 20.5
boot_diff(coded, "gpt_P1", "gpt_C1", 1, 1)  # [2.5, 39.0]
pct_diff(coded, "gpt_P1", "gpt_C1", 5, 2)   # 48.8
boot_diff(coded, "gpt_P1", "gpt_C1", 5, 2)  # [31.6, 63.8]
