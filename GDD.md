# Market Pulse — Game Design Document

**Status:** living document of what is implemented (Godot 4.6 prototype).  
**Entry scene:** `scenes/menu.tscn`  
**Save format:** `user://market_pulse_save.json` (version 9)

This is not a pitch for unbuilt features. Where something exists only as a stub, it is called out.

---

## 1. High concept

You are a day trader at a desk. Each sitting is one market session. You pick **three stocks**. Those three *are* the market. The job is not “make money in a vacuum” — it is **beat that basket**.

Fantasy: read the tape, sit through weather and stories, size trades through a real spread and commission, and leave a book that still looks good when the week is scored.

Tone: **HUD, ticket, pause, close, pick screen, and tooltips** use plain words — stock, price, headline. The **news feed** may still say *name* or *print*; those stay underlined with hover. Not a glossary screen.

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

A full session is ~6.5 minutes of real time at **1×** if you sit it out. **Tape speed** (1× / 2× / 3×) only shortens the tick interval; headline pause windows stay wall-clock. **End Session** (unlocked at **10:30**, first hour of tape) fast-forwards remaining ticks to the close. News still fires; player-triggered “drama” does not start (spectator mode). Already-queued drama beats can still print.

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

Twelve companies. Risk is the player-facing lever.

| Symbol | Name | Sector | Risk |
| --- | --- | --- | --- |
| NMIN | North Mining Ltd | Materials | Safe |
| RETL | Redline Retail | Consumer | Safe |
| BANK | Bastion Bank | Financials | Safe |
| FOOD | Harbor Foods | Consumer | Safe |
| ALPH | Alpha Technologies | Technology | Growth |
| HELX | Helix Biotech | Healthcare | Growth |
| AERO | Aether Aerospace | Industrials | Growth |
| NOVA | Nova Mobility | Industrials | Growth |
| GRNE | Green Energy Corp | Energy | Volatile |
| CYBR | CyberNest Inc | Technology | Volatile |
| QBIT | Qubit Labs | Technology | Volatile |
| DRFT | Drift Interactive | Technology | Volatile |

**Safe** — smaller swings, harder to outrun the basket in a hurry. Typical day roughly ±0.4–1.2%.  
**Growth** — moderate; news still pays or costs. Typical day ±1–3%.  
**Volatile** — headlines can gap the name. Typical day ±3–8%.

The pick screen is **three columns** (safe / growth / volatile) so all twelve stocks are on one screen. Each card shows ticker, company, sector, cap, typical day, and a **three-line story**. Ticker, name, and the info line share the same height on every card. The mix line summarizes conservative, defensive, mixed, tilted growth / defensive, high risk, or aggressive. That mix is the risk of the whole run until you rebalance.

Prices are clamped between **$1** and **$1000** while listed. Distressed residuals floor at **$0.05**. Spread is a function of liquidity (much wider when distressed): you **buy the ask, sell the bid**. Last print sits in between.

---

## 7. Money and orders

- Starting cash: **$10,000**
- Commission: **$2 + 0.2%** of notional, **every** fill (buy, sell, short open, short cover)
- Quantity: ±1, presets 10 / 20 / 50 / 100, Max (affordable on buy; short size on short)
- No options, no limit orders — marketable size at current bid/ask
- **Short** — synthetic intraday short on one listed stock you do not hold. Pays if that last **price** falls. Cap **20% of book** (cash + longs, not including open short P/L). One short per stock; sell the long first. Commission on open and cover. Cover anytime, or auto-cover at the close. Counts in vs Market (book value includes short P/L). Cannot short halted/distressed stocks. Save key is still `fades`.
- Average cost tracked per name; position P/L vs that cost

HUD shows estimated price, notional, commission, and final debit/credit before you hit Place Order. A successful fill **pulses** the watchlist card and book, and a chip flies between them (buy/short from card → book; sell/cover the other way).

---

## 8. Session HUD (desk)

Default window **1600×900**. Body is a **trade ticket** column (full height) plus **DeskRows**.

**Top row:** watchlist | chart.  
**Bottom row:** book | news feed.  
**Narrow** (window width **< 1100**): those rows stack vertically; the ticket still sits in the body column.

1. **Watchlist** — ticker cards: risk, last, day change, volume, **LONG n ±$P/L** or **SHORT n ±$P/L** (purple border when short), mini chart. Click to select.
2. **Chart** — selected stock, timeframes, main line chart. **Story cards** sit under the chart like pick cards: **ticker · stage** (or sector / TAPE), then a two-line hook; **HALTED** / **DISTRESSED** if listed that way. Wipe arcs say **Make-or-break tomorrow.** Click a **company** story card to select that watchlist ticker.
3. **News feed** — timestamped headlines with a reaction line. Tags include ticker, **MARKET**, sector shorts, and **YOUR TAPE** (gift or trap). Desk terms are **underlined**; hover for a short definition.
4. **Trade ticket** — selected stock, bid/ask, buy/sell/**short**, qty, **Buy / Sell / Short / Cover**.
5. **Book** — longs and short rows, open P/L.

Top bar: book value, cash, session P/L, clock, **vs Market**.  
Bottom bar: calendar heading (`DAY n (Weekday, Week w)`), **MARKET STATUS**, Settings, End Session / New Day, Leave desk.

**Act on this headline:** chain beats, major headlines, existential halt **and** distressed reopen, weather flips, and YOUR TAPE pause the tape **10 real seconds** (major / chain / weather / YOUR TAPE) or **14** (existential wipe). **Continue** (or timeout) resumes. To ticket selects the named watchlist stock and resumes — you still size the order on the live tape. Circuit volatility halt/reopen does **not** open this overlay. Premarket and open/close system lines skip it. End Session / leave desk treats a pause as Continue. Fast-forward to close does not pause.

Chart windows **1M / 5M / 15M / 1H / 1D** are **last N one-minute prices**, not calendar months and not OHLC candles. Tooltips say so. While the session is **closed**, HALTED / DISTRESSED is **not** drawn as a chart banner — it is folded into the close overlay stamp.

**Settings:** compact centered overlay (dim + panel), not a full-window dialog. Tape speed **1× / 2× / 3×** (tick interval only). Pause windows stay wall-clock. Close or click the dim to dismiss.

**Close overlay:** translucent panel over the chart — large **vs Market**, Beat / Matched / Lost, streak, one book-vs-story line, tomorrow’s hook, listing stamp (`Market closed` / `HALTED` / `DISTRESSED · sell-only residual`).

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

**Can wipe:** GRNE subsidy dies, HELX trial miss, HELX filing delay, CYBR award loss, QBIT demo collapse, DRFT launch collapse.  
**Cannot wipe:** safe stocks, ALPH product delays, NOVA fleet slips, macro/policy resolutions.

Sequence:

1. Close hook may read **“resolution tomorrow. Make-or-break.”** if polarity is already negative.
2. The print **halts** the name (no buys or sells). Premarket/overnight: halt until the 9:30 bell. Intraday: halt 3–8 market minutes.
3. **Reopen** gaps **−80% to −95%** (bypasses the usual 12% tick cap). Floor **$0.05**. Card shows **DISTRESSED**.
4. **Sell-only**, fat spread. Still in the three-name average until week recap.
5. **Week recap forces replacement.** Residual shares flatten at the bid. You cannot keep a distressed name.

Sell **before** the print (after the hook) and you keep the cash. Stay long through it and that sleeve of the book can go near-zero.

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
- CYBR contract; QBIT demo; DRFT launch
- RETL holiday; AERO program; NOVA fleet; BANK credit; FOOD costs
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

Leave-desk choice: **keep positions** overnight, or **cash out** (sell all at the bid) then leave.

---

## 12. Weeks (internally “chapters”)

Every **5** closed sessions: **Week Recap**.

Copy: week number, Monday–Friday span, book $ start → end, days ahead of the market, average vs Market, climate, streak, watchlist.

Then **rebalance**: keep the three, or drop one (sold at the bid) and add a name that is not on the board. Next week starts with that book.

Player-facing word is **week**. Save keys still say `chapter`.

---

## 13. Drama (player-triggered tape)

Separate from authored arcs. After a **meaningful** buy or sell (and some hold / miss-the-move checks), a delayed headline and move can fire. **~50/50 gift vs trap** when a beat is eligible. Capped at **two per day**, with gaps between events. Tagged **YOUR TAPE** in the feed (`gift` or `trap`). Examples: flow confirms a dip-buy; sellers stay on a name you faded by selling; chase-buy then dump; sold a winner then it rips. Does not **start** new drama while the engine is catching the tape up to the close; already-queued beats still print. Does not fire on halted/distressed names.

---

## 14. Persistence

One local save. New game **deletes** it after you lock three names.

Saved: cash, holdings, avg cost, **fades**, watchlist, last prices, listings, days played, commissions, regime climate, event chains, equity ATH, streak and vs-Market stats, week recap pending, leave-desk timestamp, **tape speed**.

Menu **Continue** card is a cliffhanger: day/week, book, ATH, watchlist, climate (with days left **there** — designer/career info, not the live HUD tooltip), streak, story hook, last close vs Market, overnight-risk line if away is due.

---

## 15. Teaching

No tutorial mission. Learning is:

- HUD tooltips (P/L, vs Market, book, bid/ask, commission, chart windows, market status)
- Underlined terms in news (`tape`, `print`, `hawkish`, `guidance`, `Overweight`, …)
- Close text and week recap stating whether you beat the basket

---

## 16. Explicitly not shipped

- Layout options in Settings (speed is the only setting)
- Multiplayer / social
- Auto-sim of many missed **calendar** days (only the single 8-hour away step)
- Daily “shop a new watchlist” outside week recap
- Broker-style shorts (borrow/margin). Ticket **Short** is a synthetic intraday short; it covers at the close.
- Limit orders, more than three names
- `command_handler.gd` — CLI leftover, not wired to the desk
- Scene stub `%SettingsDialog` (`AcceptDialog`) — unused; settings is the overlay in `main.gd`

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
| Short cap | 20% of cash + longs |
| Tape speed | 1× / 2× / 3× (tick wait only) |
| Print pause | 10s typical / 14s existential |
| Week length | 5 trading days |
| Away trigger | 8 real hours |
| Max active arcs | 2 |
| Beat threshold | ±0.05% vs Market |
| Narrow layout | width < 1100 px |
| Default window | 1600 × 900 |
