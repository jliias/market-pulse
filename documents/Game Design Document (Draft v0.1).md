# Game Design Document (Draft v0.1)

# Working Title
**Market Pulse**

*(Working title only. Final title to be decided later.)*

---

# High-Level Concept

Market Pulse is a single-player stock day trading simulation game where the player attempts to grow a trading account by buying and selling stocks during a simulated trading session.

Unlike a traditional financial simulator, the game focuses on decision making, timing, psychology, and reacting to rapidly changing market conditions rather than deep accounting or investing.

The market is driven by a combination of:

- simulated supply and demand
- random market movement
- company-specific events
- global news
- trading volume
- player actions (optional future feature)

The objective is simple:

> Finish the trading session with as much profit as possible.

---

# Design Goals

The game should be:

- Easy to learn
- Difficult to master
- Fast-paced
- Tense
- Replayable
- Based on believable (not necessarily realistic) market behavior

The player should constantly ask:

- Is this stock about to break out?
- Should I sell now?
- Is this dip temporary?
- Is the news already priced in?
- Should I switch to another stock?

---

# Target Platforms

Initial targets:

- Android
- Windows PC

Possible future platforms:

- iOS
- Linux
- Web

---

# Target Audience

Players interested in:

- stock markets
- finance
- management games
- strategy games
- simulation games
- economic games

No prior investing knowledge should be required.

---

# Core Gameplay Loop

1. Trading session begins.
2. Initial news appear.
3. Player watches price movement.
4. Player buys shares.
5. New events happen.
6. Prices react.
7. Player sells or buys more.
8. Repeat until market closes.
9. Score is calculated.

---

# Session Length

Prototype:

Unlimited session.

Later options:

- 5 minutes
- 10 minutes
- 20 minutes
- Full trading day (accelerated)

---

# Initial Market

Prototype:

Three simulated companies.

Example:

- Alpha Technologies
- Green Energy Corp
- North Mining Ltd

Names are placeholders.

Each company has:

- current price
- bid price
- ask price
- traded volume
- volatility
- market sentiment

---

# Starting Capital

Example:

$10,000

Player begins with:

- cash only
- no owned shares

---

# Trading Rules

Player may:

- Buy
- Sell
- Hold

No short selling initially.

No leverage.

No options.

No derivatives.

These may become advanced game modes later.

---

# Transaction Costs

Every transaction includes:

Example:

- $2 fixed commission

or

- 0.2% commission

or both.

Transaction costs prevent unrealistic rapid trading.

---

# Price Simulation

Each stock continuously updates.

Prototype update interval:

**5 seconds**

Later:

Adjustable.

Possible values:

- 0.5 s
- 1 s
- 2 s
- 5 s
- 10 s

Every update recalculates:

- price
- volume
- volatility
- momentum

---

# Market Simulation

Price changes should never feel completely random.

Each update combines:

## Base Random Movement

Small natural fluctuations.

Example:

±0.2%

---

## Trend

Bullish

Bearish

Sideways

Trend changes over time.

---

## Momentum

Recent movement affects future probability.

Strong buying pressure tends to continue briefly.

Strong selling pressure behaves similarly.

---

## Volume Influence

Large volume:

- stronger moves
- higher confidence

Low volume:

- noisier movement
- more fake breakouts

---

## News Impact

News creates temporary effects.

Positive news:

- contract wins
- earnings beat
- analyst upgrades
- successful product

Negative:

- CEO resignation
- lawsuit
- failed earnings
- product recall

Global:

- interest rate changes
- recession fears
- geopolitical tensions

---

# News System

A scrolling news feed displays events.

Examples:

> Alpha Technologies announces record quarterly earnings.

> Green Energy receives government subsidy.

> North Mining reports unexpected production shutdown.

Each event contains:

- timestamp
- headline
- affected stock(s)
- sentiment
- expected impact duration

Some news may affect:

- one company
- an entire industry
- the whole market

---

# Player Interface

Prototype (Text)

--------------------------------

Time

Cash

Portfolio value

Profit/Loss

Available cash

--------------------------------

Stock A

Price

Volume

Owned shares

--------------------------------

Stock B

...

--------------------------------

News feed

--------------------------------

Commands:

BUY A 50

SELL B 20

STATUS

HELP

QUIT

---

# Planned Graphical UI

Upper section:

- Account value
- Cash
- Total profit

Center:

Sliding live price charts

One graph per stock or combined view.

Indicators (future):

- Moving Average
- VWAP
- RSI
- MACD

Lower section:

Scrolling news ticker

Bottom:

Buy/Sell buttons

Portfolio

Recent trades

---

# Artificial Market Behaviour

Each stock has hidden properties.

Examples:

Volatility

Growth

Liquidity

Popularity

Institutional ownership

Speculation factor

These influence future movement.

---

# Difficulty Levels

Easy

- fewer surprises
- slower trends
- stronger news effects

Normal

Balanced market.

Hard

- fake breakouts
- higher volatility
- misleading trends

Expert

Highly realistic randomness.

---

# Win Condition

Session ends.

Player score based on:

Final Portfolio Value

Profit %

Sharpe-like stability bonus (future)

Maximum drawdown penalty (future)

---

# Loss Condition

No hard failure.

Possible optional mode:

Bankruptcy.

---

# Progression

Future additions:

Unlock:

- additional companies
- sectors
- larger markets
- advanced indicators
- new news categories
- economic events

---

# Statistics

Track:

Highest profit

Largest loss

Best trade

Worst trade

Winning %

Average holding time

Total commissions

Largest drawdown

Portfolio growth

---

# Audio

Prototype:

None.

Later:

- market opening bell
- notification sounds
- breaking news alert
- successful trade
- warning sounds

Ambient soundtrack optional.

---

# Technical Prototype

Platform:

Godot

Prototype:

Text interface.

Three stocks.

5-second updates.

Console commands:

BUY

SELL

WAIT

STATUS

HELP

QUIT

Simulation runs continuously.

---

# Future Features

- Candlestick charts
- Multiple exchanges
- AI competitors
- Online leaderboards
- Career mode
- Daily challenges
- Historical market scenarios
- Random market crashes
- Insider rumors
- Dividend announcements
- Earnings calendar
- Trading achievements
- Replay mode
- Portfolio analytics
- Market heat map
- Watchlist
- Sector rotation
- Tutorial campaign

---

# Design Philosophy

The game should never become a spreadsheet simulator.

Instead, it should create the emotional experience of active trading:

- excitement
- uncertainty
- fear
- greed
- patience
- regret
- satisfaction

A successful player wins by interpreting incomplete information, reacting quickly to changing conditions, and managing risk rather than predicting the future with certainty.