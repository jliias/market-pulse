# Market Pulse — Game Design Document

**Status:** living document of what is implemented (Godot 4.6 prototype, **high-pulse** branch: full 12-stock board).  
**Entry scene:** `scenes/menu.tscn`  
**Save format:** `user://market_pulse_save.json` (version 10)

This is not a pitch for unbuilt features. Where something exists only as a stub, it is called out.

---

## 1. High concept

You are a day trader at a desk. Each sitting is one market session. **All twelve stocks** are on the board. Click a card to choose which stock you are trading; switch anytime. The job is not “make money in a vacuum” — it is **beat the listed board**.

Fantasy: read the tape, sit through weather and stories, size trades through a real spread and commission, and leave a book that still looks good when the week is scored.

Tone: **HUD, ticket, pause, close, feed, and tooltips** use **stock** (not *name*). **Print** in the feed means an official number (earnings, inflation, traffic). “No news” lines say **headline** / **news**, not print. Desk terms stay underlined with hover. Not a glossary screen.

---

## 2. Win / lose

There is no campaign finale. The score is **session vs Market**.

| Result | Rule |
| --- | --- |
| Beat the market | Your session return minus the listed-board average is **> +0.05%** |
| Market beat you | That gap is **< −0.05%** |
| Matched | Everything in between |

A **beat streak** counts consecutive days you beat the market. A day the market beats you **zeros the streak**. Matching does not extend it and does not break it.

Career extras (shown on close, menu, week recap): book value, all-time high, best/worst vs Market, days ahead of the market this week.

You can go broke in practice (cash + positions near zero) but there is no explicit game-over screen.

---

## 3. Core loop

```
Menu → (new) desk with all 12 stocks → session
  10s preopen; countdown sits on the price chart (headlines already on the feed)
  9:30 open bell → trade until 16:00 or End Session (after 10:30)
  Close overlay: result, streak, story hook
  New Day  (or Week Recap every 5 days)
Leave desk → save + timestamp → menu or quit
```

**Continue** loads the book, board, prices, climate, and open stories. If you were gone **≥ 8 real hours**, one overnight step is applied before the next sitting (see §11).

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

## 5. The market (the listed board)

The “market” is the **equal-weighted average price** of **listed** stocks on the board (all twelve, minus any **distressed** names). Session market return is that average vs its **open** print (after premarket gaps).

Your **vs Market** line is:

`your book return this session − market return`

Sitting in cash while names rally **loses vs Market**. Being long the names that gap and fade can win even if the book is red.

The board is always the full universe. Click a card to select the stock on the ticket; switch during the session. Default universe order: NMIN, RETL, BANK, FOOD, ALPH, HELX, AERO, NOVA, GRNE, CYBR, QBIT, DRFT.

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

All twelve stocks sit on the desk from New Game as a quote board (scanner rows, not fat cards).

Prices are clamped between **$1** and **$1000** while listed. Distressed residuals floor at **$0.05**. Spread is a function of liquidity (much wider when distressed): you **buy the ask, sell the bid**. Last print sits in between.

---

## 7. Money and orders

- Starting cash: **$10,000**
- Commission: **$2 + 0.2%** of notional, **every** fill (buy, sell, short open, short cover)
- Quantity: ±1, presets 10 / 20 / 50 / 100, Max (affordable on buy; short size on short)
- No options, no limit orders — marketable size at current bid/ask
- **Short** — synthetic intraday short on one listed stock you do not hold. Pays if that last **price** falls. Cap **20% of book** (cash + longs, not including open short P/L). One short per stock; sell the long first. Commission on open and cover. Cover anytime, or auto-cover at the close. Counts in vs Market (book value includes short P/L). Cannot short halted/distressed stocks. Save key is still `fades`.
- Average cost tracked per name; position P/L vs that cost

HUD shows estimated price, notional, commission, and final debit/credit before you hit Place Order. A successful fill **pulses** the board row and book, and a chip flies between them (buy/short from row → book; sell/cover the other way).

---

## 8. Session HUD (desk)

Default window **1600×900**. Body is three full-height columns: **board** | **chart + tape** | **trade ticket**.

**Narrow** (window width **< 1100**): those columns stack (board, desk, ticket).

1. **Board** — full-height quote list of all **12** stocks. Header reads **BOARD · 12 listed**. Rows are scanner lines (not fat cards): ticker, risk tag (SAFE / GRW / VOL, or HALT / DST), last-tick arrow, last, day %, position (`L20` / `S10`), and **open P/L** in dollars (green/red) when you have a long or short. Gold bar marks the stock on the ticket. Hover a ticker for company, typical day, and session L/H. Click any row to trade that stock. **Book** sits under the list (holdings + open P/L). Session **volume** is on the main chart (`VOL 1.24M`).
2. **Chart** — selected stock, timeframes, main line chart (volume pane labeled **VOL** plus session total). **Story cards** sit under the chart: **ticker · stage** (or sector / TAPE), then a two-line hook (**Further news is still expected.** / after a twist **The picture looks mixed.** / wipe-path **A big headline is rumored in the coming days.**); **PAUSE** / **MAKE-OR-BREAK** / **DISTRESSED** if listed that way. A **NEW** stamp (gold) means headlines landed on that card since you last opened it. Click a card for a short overlay of that arc’s **topic log** (day · time · headline) plus a lean line (**looks better / worse** for the stock, sector, or market — or **looks mixed** after a twist). Company cards log that name’s tape; sector cards log that sector’s tagged tape only; market cards log MARKET prints. The session feed still clears at New Day. Opening the card clears **NEW**. **Select TICKER** jumps the ticket to that stock.
3. **News feed** — under the chart, full width of the desk. Timestamped headlines with a reaction line. Tags include ticker, **MARKET**, sector shorts, and **YOUR TAPE** (gift or trap). Desk terms are **underlined**; hover for a short definition.
4. **Trade ticket** — selected stock, bid/ask, buy/sell/**short**, qty, **Buy / Sell / Short / Cover**. Switching to a stock with a **short** arms **Short** (cover); a **long** arms **Sell**; flat arms **Buy**. You can still change the side by hand. Message line is fills and blocks only (halted, closed, pause). Headlines stay in the feed / pause overlay; the day result stays on the close panel.

Top bar: book value, cash, session P/L, clock, **vs Market**, Settings, Menu.  
Bottom bar: calendar heading (`DAY n (Weekday, Week w)`), **MARKET STATUS**, End Session / New Day. Leave desk is **Menu**.

**Act on this headline:** pause the tape **10 real seconds** (YOUR TAPE, weather flip, story **resolution** on the **selected stock or a stock you hold/short**, or a **major** company headline on those same names) or **14** (existential halt / distressed reopen — any name). Follow-ups, twists, sector tape, and market-wide filler stay in the feed only. Circuit volatility halt/reopen does **not** open this overlay. **Continue** (or timeout) resumes. **Select TICKER** selects that stock and resumes. Pause headline and reaction use the same underlined hover terms as the feed. Premarket and open/close system lines skip it. End Session / leave desk treats a pause as Continue. Fast-forward to close does not pause.

Chart windows **1M / 5M / 15M / 1H / 1D** are **last N one-minute prices**, not calendar months and not OHLC candles. Tooltips say so. While the session is **closed**, HALTED / DISTRESSED is **not** drawn as a chart banner — it is folded into the close overlay stamp.

**Settings:** compact centered overlay (dim + panel), not a full-window dialog. Tape speed **1× / 2× / 3×** (tick interval only). Pause windows stay wall-clock. Close or click the dim to dismiss.

**Close overlay:** translucent panel over the chart — large **vs Market**, Beat / Matched / Lost, streak, one book-vs-story line, **Story:** hook (not dated to tomorrow), listing stamp (`Market closed` / `HALTED` / `DISTRESSED · sell-only residual`).

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

Two outcomes share the same **HALTED** listing, but the stamp differs:

- **Resume (circuit):** growth and volatile stocks only, **once per stock per day**. Card / chart / close: **HALTED · listed** (full line: volatility pause · reopens listed). Pause overlay does **not** open. Fast-forward to close does not fire new circuits.
- **Distress (existential):** tagged negative resolutions. Stamp: **HALTED · make-or-break** (reopens distressed). Pause overlay **does** open.

A name already halted or distressed cannot take a second halt.

### Existential resolutions (halt → distressed)

A **negative resolution** on a tagged company arc can **wipe the equity stub**, not just print a normal dip.

**Can wipe:** GRNE subsidy dies, HELX trial miss, HELX filing delay, CYBR award loss, QBIT demo collapse, DRFT launch collapse.  
**Cannot wipe:** safe stocks, ALPH product delays, NOVA fleet slips, macro/policy resolutions.

Sequence:

1. Close hook may read **“desks expect a major update in the coming days”** if polarity is already negative. That rumor lasts **2–5** more sessions (rolled when it first appears). If the print does not land by then, the rumor **dies**: the wipe does not fire, the card drops, and the next premarket can say the update never landed.
2. The print **halts** the name (no buys or sells). Premarket/overnight: halt until the 9:30 bell. Intraday: halt 3–8 market minutes.
3. **Reopen** gaps **−80% to −95%** (bypasses the usual 12% tick cap). Floor **$0.05**. Card shows **DISTRESSED**.
4. **Sell-only**, fat spread. **Out of** the listed-board average until it is no longer distressed.
5. **Week recap flattens leftover shares** at the bid. The name stays on the board, sell-only.

Sell **before** the print (after the hook) and you keep the cash. Stay long through it and that sleeve of the book can go near-zero.

### Random tape

Company, sector, and market headlines (premarket and live). Strength **minor / moderate / major**. Some **last** (they keep pulling the name); others are a one-print rumor. Names **interpret** news (fade, partial, crowded) — the headline is not a guaranteed fill in that direction.

Feed is capped (~50). Premarket pack is a few items so the open is not a wall of text.

### Authored arcs (event chains)

Up to **two** stories active. At most **one** tape-wide (sector / market) story; the other slot prefers a **company** arc when one is available. Stages: announcement → follow-up → reaction → twist → resolution. Stages can **skip**. Beats can prefer premarket. Close screen (and menu) surface a **story hook** (wipe-path: major update in the coming days). Each open card keeps a **topic log** (day · time · headline) for the life of the arc. Company cards log that name’s tape; sector cards log that sector’s tape only (not every company headline on a name in the group); market cards log MARKET prints. After a **twist** prints, the card hook is **The picture looks mixed.** otherwise **Further news is still expected.** (wipe rumor excepted).

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
- Board **gaps** by risk (volatile names can move more)
- At most one chain beat, rewritten as `OVERNIGHT:`
- Does **not** increment `days_played` / week / streak
- Cleared after apply

If a **week recap** is pending, that overlay still comes first.

Leave-desk choice: **keep positions** overnight, or **cash out** (sell all at the bid) then leave.

---

## 12. Weeks (internally “chapters”)

Every **5** closed sessions: **Week Recap**.

Copy: week heading, book $ start → end, days ahead of the market, climate, streak as separate lines (same rhythm as close). Board tickers as chips. Distressed is its own line; leftover shares flatten at the bid. **No watchlist rebalance** — the board stays all twelve.

Player-facing word is **week**. Save keys still say `chapter`.

---

## 13. Drama (player-triggered tape)

Separate from authored arcs. After a **meaningful** buy or sell (and some hold / miss-the-move checks), a delayed headline and move can fire. **~50/50 gift vs trap** when a beat is eligible. Capped at **two per day**, with gaps between events. Tagged **YOUR TAPE** in the feed (`gift` or `trap`). Examples: flow confirms a dip-buy; sellers stay on a name you faded by selling; chase-buy then dump; sold a winner then it rips. Does not **start** new drama while the engine is catching the tape up to the close; already-queued beats still print. Does not fire on halted/distressed names.

---

## 14. Persistence

One local save. New game **deletes** it when you start from the menu.

Saved: cash, holdings, avg cost, **fades**, board (`watchlist` key still stores all twelve), last prices, listings, days played, commissions, regime climate, event chains, equity ATH, streak and vs-Market stats, week recap pending, leave-desk timestamp, **tape speed**.

Menu **Continue** card is a cliffhanger: day/week, book, ATH, board, climate (with days left **there** — designer/career info, not the live HUD tooltip), streak, story hook, last close vs Market, overnight-risk line if away is due.

---

## 15. Teaching

No tutorial mission. Learning is:

- HUD tooltips (P/L, vs Market, book, bid/ask, commission, chart windows, market status)
- Underlined terms in news (`tape`, `print`, `hawkish`, `guidance`, `Overweight`, …)
- Close text and week recap stating whether you beat the basket

---

## 16. Explicitly not shipped

- Layout options in Settings (speed is the only setting)
- Audio / soundtrack
- Multiplayer / social
- Auto-sim of many missed **calendar** days (only the single 8-hour away step)
- Daily “shop a new watchlist”
- Broker-style shorts (borrow/margin). Ticket **Short** is a synthetic intraday short; it covers at the close.
- Limit orders
- Three-name pick screen (`watchlist_select.tscn` is leftover, not on the New Game path)
- `command_handler.gd` — CLI leftover, not wired to the desk
- Scene stub `%SettingsDialog` (`AcceptDialog`) — unused; settings is the overlay in `main.gd`

---

## 17. Design pillars (as implemented)

1. **Beat the listed board** — the market is not an index future; it is the equal-weight average of listed names.
2. **Time pressure is real but skippable** — sit the tape or mark to close after the first hour.
3. **Stories persist** — arcs and climate survive the night; away risk is one overnight, not a punishment sim of idle weeks.
4. **Language is the texture** — teach bid/ask, tape, and climate in the UI, not in a manual.
5. **Switch on the fly** — all twelve are tradable; the loadout is which sleeves you sit in, not which three you locked.

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
