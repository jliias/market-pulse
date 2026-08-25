# Market Pulse — Game Design Document

**Status:** living document of what is implemented (Godot 4.6 prototype).  
**Entry scene:** `scenes/menu.tscn`  
**Save format:** `user://market_pulse_save.json` (version 8)

This is not a pitch for unbuilt features. Where something exists only as a stub, it is called out.

---

## 1. High concept

You are a day trader at a desk. Each sitting is one market session. You pick **three names**. Those three *are* the market. The job is not “make money in a vacuum” — it is **beat that basket**.

Fantasy: read the tape, sit through weather and stories, size trades through a real spread and commission, and leave a book that still looks good when the week is scored.

Tone: desk language in the feed, taught in place (hover), not a glossary screen.

---

## 2. Win / lose

There is no campaign finale. The score is **session vs Market**.

| Result | Rule |
| --- | --- |
| Beat the market | Your session return minus the three-name average is **> +0.05%** |
| Market beat you | That gap is **< −0.05%** |
| Matched | Everything in between |

A **beat streak** counts consecutive days you beat the market. A day the market beats you **zeros the streak**. Matching does not extend it and does not break it.

Career extras (shown on close, menu, week recap): book value, all-time high, best/worst vs Market, days ahead of the market this week.

You can go broke in practice (cash + positions near zero) but there is no explicit game-over screen.

---

## 3. Core loop

```
Menu → (new) pick 3 names → session
  10s preopen overlay (headlines already on the feed)
  9:30 open bell → trade until 16:00 or End Session (after 10:30)
  Close overlay: result, streak, tomorrow’s story hook
  New Day  (or Week Recap every 5 days)
Leave desk → save + timestamp → menu or quit
```

**Continue** loads the book, watchlist, prices, climate, and open stories. If you were gone **≥ 8 real hours**, one overnight step is applied before the next sitting (see §11).

---

## 4. Time

| Layer | Rule |
| --- | --- |
| Session clock | **09:30–16:00** (390 market minutes) |
| Real time | **1 real second = 1 market minute** |
| Tick | One price/news step per second while the tape runs |
| Calendar | **Mon–Fri only.** Day 1 = Monday, day 5 = Friday, day 6 = Monday of week 2 |
| HUD day | Shows the **open session’s** day while you are in it; after close it stays on the day you just finished until New Day |

A full session is ~6.5 minutes of real time if you sit it out. **End Session** (unlocked at **10:30**, first hour of tape) fast-forwards remaining ticks to the close. News still fires; player-triggered “drama” does not (spectator mode).

Leaving the desk while the market is open **marks to close** the same way, then saves.

---

## 5. The market (your three names)

The “market” is the **equal-weighted average price** of the current watchlist. Session market return is that average vs its **open** print (after premarket gaps).

Your **vs Market** line is:

`your book return this session − market return`

Sitting in cash while names rally **loses vs Market**. Being long the names that gap and fade can win even if the book is red.

Watchlist size is **exactly 3**, chosen at new game and optionally swapped at week recap. Default if something goes wrong: ALPH, GRNE, NMIN.

---

## 6. Universe

Ten companies. Risk is the player-facing lever.

| Symbol | Name | Sector | Risk |
| --- | --- | --- | --- |
| NMIN | North Mining Ltd | Materials | Safe |
| RETL | Redline Retail | Consumer | Safe |
| BANK | Bastion Bank | Financials | Safe |
| FOOD | Harbor Foods | Consumer | Safe |
| ALPH | Alpha Technologies | Technology | Growth |
| HELX | Helix Biotech | Healthcare | Growth |
| AERO | Aether Aerospace | Industrials | Growth |
| GRNE | Green Energy Corp | Energy | Volatile |
| CYBR | CyberNest Inc | Technology | Volatile |
| QBIT | Qubit Labs | Technology | Volatile |

**Safe** — smaller swings, harder to outrun the basket in a hurry. Typical day roughly ±0.4–1.2%.  
**Growth** — moderate; news still pays or costs. Typical day ±1–3%.  
**Volatile** — headlines can gap the name. Typical day ±3–8%.

The pick screen summarizes the **mix** (conservative, mixed, aggressive, etc.). That mix is the risk of the whole run until you rebalance.

Prices are clamped between **$1** and **$1000** while listed. Distressed residuals floor at **$0.05**. Spread is a function of liquidity (much wider when distressed): you **buy the ask, sell the bid**. Last print sits in between.

---

## 7. Money and orders

- Starting cash: **$10,000**
- Commission: **$2 + 0.2%** of notional, **every** fill (buy and sell)
- Quantity: ±1, presets 10 / 20 / 50 / 100, Max (affordable on buy)
- No shorts, no options, no limit orders — marketable size at current bid/ask
- Average cost tracked per name; position P/L vs that cost

HUD shows estimated price, notional, commission, and final debit/credit before you hit Place Order.

---

## 8. Session HUD (desk)

Three columns (stack on a narrow window):

1. **Watchlist** — ticker cards: risk, last, day change, volume, shares owned, mini chart. Click to select.
2. **Chart + news** — main line chart; feed of timestamped headlines with a reaction line. Desk terms in the feed are **underlined**; hover for a short definition.
3. **Trade ticket + book** — selected name, bid/ask, buy/sell, qty, fills, cash, positions, session P/L.

Top: book value, cash, session P/L, clock, **vs Market**.  
Bottom: calendar heading (`DAY n (Weekday, Week w)`), **MARKET STATUS**, End Session / New Day.

Chart windows **1M / 5M / 15M / 1H / 1D** are **last N one-minute prints**, not calendar months and not OHLC candles. Tooltips say so.

**Settings** is a stub (“later pass”).

---

## 9. Market status (climate + weather)

Shown as e.g. `BEAR MARKET · EUPHORIA`. Hover explains the mix; it does **not** count remaining climate days.

**Climate** (lasts several trading days, drifts on close / overnight):

- **Bull** — lasting up tilt; dips more likely to get bought
- **Bear** — lasting down tilt; rallies more likely to fail
- **Normal** — no lasting tilt; the session can still swing

**Weather** (intraday, minutes of tape):

- **Panic** — fast selling on top of climate
- **Euphoria** — fast buying on top of climate
- **High vol** — stretched ranges, both sides can print hard

Odd pairings are intentional (bear + euphoria = bounce in a down market that can still fail). Climate can be born from a major market-story resolution, from a day that spent a long time in panic/euphoria, or from a quiet random roll. Weather can fire off major/broad/twist headlines.

---

## 10. News and stories

Two layers:

### Halts

Two outcomes share the same **HALTED** card:

- **Resume (circuit):** growth and volatile names only, **once per name per day**. If price moves about **5% (growth)** or **8% (volatile)** in five market minutes, trading pauses 2–5 minutes, then the name **reopens listed** near the last print. Safe names never circuit. Fast-forward to close does not fire new circuits.
- **Distress (existential print):** tagged negative resolutions still halt, then reopen **−80% to −95%**, sell-only, forced off the board at week recap (see below).

A name already halted or distressed cannot take a second halt.

### Existential resolutions (halt → distressed)

A **negative resolution** on a tagged company arc can **wipe the equity stub**, not just print a normal dip.

**Can wipe:** GRNE subsidy dies, HELX trial miss, HELX filing delay, CYBR award loss, QBIT demo collapse.  
**Cannot wipe:** safe names, ALPH product delays, macro/policy resolutions.

Sequence:

1. Close hook may read **“resolution tomorrow. Binary.”** if polarity is already negative.
2. The print **halts** the name (no buys or sells). Premarket/overnight: halt until the 9:30 bell. Intraday: halt 3–8 market minutes.
3. **Reopen** gaps **−80% to −95%** (bypasses the usual 12% tick cap). Floor **$0.05**. Card shows **DISTRESSED**.
4. **Sell-only**, fat spread. Still in the three-name average until week recap.
5. **Week recap forces replacement.** Residual shares flatten at the bid. You cannot keep a distressed name.

Flatten **before** the print (after the hook) and you keep the cash. Hold through it and that sleeve of the book can go near-zero.

### Random tape

Company, sector, and market headlines (premarket and live). Strength **minor / moderate / major**. Some **last** (they keep pulling the name); others are a one-print rumor. Names **interpret** news (fade, partial, crowded) — the headline is not a guaranteed fill in that direction.

Feed is capped (~50). Premarket pack is a few items so the open is not a wall of text.

### Authored arcs (event chains)

Up to **two** stories active. Stages: announcement → follow-up → reaction → twist → resolution. Stages can **skip**. Beats can prefer premarket. Close screen (and menu) surface a **hook** for tomorrow.

Implemented arcs (company or tape-wide):

- ALPH Nexis accelerator; ALPH cloud
- GRNE subsidy; GRNE storage
- NMIN pit; NMIN offtake
- HELX trial; HELX FDA
- CYBR contract; QBIT demo
- RETL holiday; AERO program; BANK credit; FOOD costs
- Tape: growth rotation, hawkish tape, consumer traffic, commodities swing, inflation print

---

## 11. Overnight and “away”

**New Day in the same sitting** rolls prices to the next session, runs premarket, 10-second open countdown. Does **not** increment week/day until that session closes.

**Away step** (Continue after ≥ **8 real hours** since leave-desk stamp):

- One overnight, not a skipped week
- Climate may drift
- Watchlist **gaps** by risk (volatile names can move more)
- At most one chain beat, rewritten as `OVERNIGHT:`
- Does **not** increment `days_played` / week / streak
- Cleared after apply

If a **week recap** is pending, that overlay still comes first.

Leave-desk choice: **hold** names overnight, or **cash out** (flatten all at the bid) then leave.

---

## 12. Weeks (internally “chapters”)

Every **5** closed sessions: **Week Recap**.

Copy: week number, Monday–Friday span, book $ start → end, days ahead of the market, average vs Market, climate, streak, watchlist.

Then **rebalance**: keep the three, or drop one (sold at the bid) and add a name that is not on the board. Next week starts with that book.

Player-facing word is **week**. Save keys still say `chapter`.

---

## 13. Drama (player-triggered tape)

Separate from authored arcs. After a **meaningful** buy or sell, there is a chance a delayed headline and move fire (e.g. sellers overwhelm after a chase buy; late money chases after you sold a winner). Capped per day, with gaps between events. Does not fire while the engine is catching the tape up to the close.

---

## 14. Persistence

One local save. New game **deletes** it after you lock three names.

Saved: cash, holdings, avg cost, watchlist, last prices, days played, commissions, regime climate, event chains, equity ATH, streak and vs-Market stats, week recap pending, leave-desk timestamp.

Menu **Continue** card is a cliffhanger: day/week, book, ATH, watchlist, climate (with days left **there** — designer/career info, not the live HUD tooltip), streak, story hook, last close vs Market, overnight-risk line if away is due.

---

## 15. Teaching

No tutorial mission. Learning is:

- HUD tooltips (P/L, vs Market, book, bid/ask, commission, chart windows, market status)
- Underlined terms in news (`tape`, `print`, `hawkish`, `guidance`, `Overweight`, …)
- Close text and week recap stating whether you beat the basket

---

## 16. Explicitly not shipped

- Settings (speed, layout)
- Multiplayer / social
- Auto-sim of many missed **calendar** days (only the single 8-hour away step)
- Daily “shop a new watchlist” outside week recap
- Shorts, limits, more than three names
- Legacy `command_handler.gd` (CLI leftover, not on the desk)

---

## 17. Design pillars (as implemented)

1. **Beat the basket you chose** — the market is not an index future; it is your three names.
2. **Time pressure is real but skippable** — sit the tape or mark to close after the first hour.
3. **Stories persist** — arcs and climate survive the night; away risk is one overnight, not a punishment sim of idle weeks.
4. **Language is the texture** — teach bid/ask, tape, and climate in the UI, not in a manual.
5. **Risk is the loadout** — three tickers is a build; week recap is the only re-spec.

---

## 18. Session numbers (quick reference)

| Thing | Value |
| --- | --- |
| Open / close | 09:30 / 16:00 |
| End Session unlock | 10:30 |
| Preopen overlay | 10 real seconds |
| Starting cash | $10,000 |
| Commission | $2 + 0.2% |
| Watchlist | 3 names |
| Week length | 5 trading days |
| Away trigger | 8 real hours |
| Max active arcs | 2 |
| Beat threshold | ±0.05% vs Market |
