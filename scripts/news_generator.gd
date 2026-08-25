class_name NewsGenerator
extends RefCounted

const STRENGTH_RANGE := {
	"minor": {"day": Vector2(0.003, 0.008), "pre": Vector2(0.010, 0.022)},
	"moderate": {"day": Vector2(0.009, 0.018), "pre": Vector2(0.022, 0.042)},
	"major": {"day": Vector2(0.028, 0.055), "pre": Vector2(0.040, 0.090)},
}

const INDUSTRY_KEYS: Array[String] = [
	"Technology", "Energy", "Materials", "Commodities", "Growth",
	"Healthcare", "Consumer", "Industrials", "Financials",
]

const COMPANY_NEWS := {
	"ALPH": {
		"positive": [
			{"text": "Alpha Technologies unveils a faster AI chip.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Alpha Technologies lands a multi-year cloud contract.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analyst raises Alpha Technologies price target.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Street chatter: Alpha Technologies named a top pick.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Alpha Technologies beats a mid-quarter revenue checkpoint.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Alpha Technologies says cloud utilization is running hotter than billed.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "A supply partner is said to have cleared a bottleneck for Alpha Technologies.", "category": "product", "strength": "minor", "lasting": true},
		],
		"negative": [
			{"text": "Alpha Technologies delays a flagship product launch.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Alpha Technologies warns of weaker enterprise demand.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "Analyst trims Alpha Technologies price target.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Whispers of profit-taking in Alpha Technologies.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Options flow turns sharply bearish in Alpha Technologies.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Alpha Technologies customers are said to be stretching refresh cycles.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Desk note: Alpha Technologies looks crowded after the morning bid.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "Intraday rumor: Green Energy Corp nearing a new contract.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Regulators signal multi-year support for Green Energy Corp subsidies.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Analyst upgrades Green Energy Corp to Overweight.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Green Energy Corp confirms a grid-storage win.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Hot money piles into Green Energy Corp on subsidy chatter.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Green Energy Corp says a storage interconnection slot moved up.", "category": "regulatory", "strength": "moderate", "lasting": true},
			{"text": "Power-price strength lifts Green Energy Corp on the session.", "category": "commodity", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Sector note warns of subsidy risk for Green Energy Corp.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Traders fade Green Energy Corp after the morning pop.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Analyst downgrades Green Energy Corp to Neutral.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Green Energy Corp delays a key project commissioning.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Whisper: Green Energy Corp may miss a subsidy window.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "A supplier slip is said to be hanging over a Green Energy Corp site.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Green Energy Corp is offered as power prices fade.", "category": "commodity", "strength": "minor", "lasting": false},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "North Mining Ltd reports steady production.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "North Mining Ltd extends a long-term offtake agreement.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analysts flag North Mining Ltd as oversold.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Intraday bid: North Mining Ltd sees dip-buying interest.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "North Mining Ltd lifts a local output checkpoint.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "A buyer is said to want more tonnes from North Mining Ltd.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Metals strength lifts North Mining Ltd into the afternoon.", "category": "commodity", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "North Mining Ltd flags a temporary pit disruption.", "category": "product", "strength": "moderate", "lasting": false},
			{"text": "North Mining Ltd cuts a near-term shipment guide.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "Intraday rumor: North Mining Ltd output running light.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Analyst cuts North Mining Ltd to Underweight.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Flow desks lean short North Mining Ltd into the close.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A key offtake is said to be under review at North Mining Ltd.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Bulk prices fade — North Mining Ltd is offered with the complex.", "category": "commodity", "strength": "minor", "lasting": false},
		],
	},
	"HELX": {
		"positive": [
			{"text": "Helix Biotech reports a clean readout on a mid-stage trial.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analyst raises Helix Biotech on pipeline optionality.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Helix Biotech signs a co-development pact with a larger peer.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Street chatter: Helix Biotech data looks better than billed.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Helix Biotech says a filing window still looks intact.", "category": "regulatory", "strength": "moderate", "lasting": true},
			{"text": "A larger peer is said to be circling Helix Biotech for a pact.", "category": "rumor", "strength": "moderate", "lasting": false},
		],
		"negative": [
			{"text": "Helix Biotech flags a pause in a key trial cohort.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analyst cuts Helix Biotech after a mixed data leak.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Whispers of a safety review hanging over Helix Biotech.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Helix Biotech trims a near-term launch window.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Helix Biotech is said to have drawn a request for more data.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Biotech flow dumps Helix Biotech after a crowded squeeze.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"RETL": {
		"positive": [
			{"text": "Redline Retail beats a same-store sales checkpoint.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Redline Retail lifts holiday inventory guidance.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "Analysts flag Redline Retail as a defensive consumer pick.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Intraday bid: Redline Retail sees dip-buying after a soft open.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Redline Retail says a category is tracking ahead into the holiday.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "A peer's traffic miss sends a defensive bid into Redline Retail.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Redline Retail warns of a weaker traffic print.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Analyst trims Redline Retail on margin pressure.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Whispers of a promotional war hitting Redline Retail.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Redline Retail delays a store-refresh wave.", "category": "product", "strength": "minor", "lasting": true},
			{"text": "Inventory at Redline Retail is said to look heavier than guided.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Redline Retail is offered as consumer traffic chatter turns light.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"CYBR": {
		"positive": [
			{"text": "Intraday rumor: CyberNest Inc nearing a large security contract.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "CyberNest Inc lands a multi-year government cyber award.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Analyst upgrades CyberNest Inc after a product demo.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Hot money piles into CyberNest Inc on breach-prevention chatter.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "CyberNest Inc says a bake-off is going its way.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "A peer breach note sends flow into CyberNest Inc.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Whisper: CyberNest Inc may have missed a key RFP.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Analyst downgrades CyberNest Inc to Neutral.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "CyberNest Inc delays a flagship platform release.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Traders fade CyberNest Inc after the morning squeeze.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A protest is said to be hanging over a CyberNest Inc award.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "CyberNest Inc looks crowded after the contract squeeze.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"AERO": {
		"positive": [
			{"text": "Aether Aerospace wins a multi-year defense contract.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Aether Aerospace beats a production checkpoint.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Analyst raises Aether Aerospace on backlog visibility.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Street chatter: Aether Aerospace named on a new program shortlist.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Aether Aerospace says a production lot cleared a quality gate.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Defense-flow bids Aether Aerospace on contract chatter.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Aether Aerospace flags a supply-chain slip on a key airframe.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Aether Aerospace trims a near-term delivery guide.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "Analyst cuts Aether Aerospace after a program review.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Whispers of a protest hanging over an Aether Aerospace award.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "A quality hold is said to be hanging over an Aether Aerospace lot.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Aether Aerospace is offered as industrials fade into the close.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"BANK": {
		"positive": [
			{"text": "Bastion Bank reports a clean net-interest print.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Bastion Bank lifts its capital-return commentary.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "Analysts flag Bastion Bank as oversold versus peers.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Intraday bid: Bastion Bank sees dip-buying in financials.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Bastion Bank says consumer credit looks cleaner than billed.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "A peer provision miss sends a relative bid into Bastion Bank.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Bastion Bank flags a rise in credit-loss provisions.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "Analyst cuts Bastion Bank on net-interest pressure.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Intraday rumor: Bastion Bank deposit costs running hot.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Flow desks lean short Bastion Bank into the close.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A pocket of consumer credit at Bastion Bank is said to look worse.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Bastion Bank is offered as financials fade on deposit chatter.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"FOOD": {
		"positive": [
			{"text": "Harbor Foods reports steady volume across the grocery channel.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Harbor Foods extends a private-label supply deal.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Analysts flag Harbor Foods as a defensive consumer name.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Intraday bid: Harbor Foods sees dip-buying after a soft open.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Harbor Foods says grocery mix is running ahead of volume.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Input costs are said to be easing for Harbor Foods.", "category": "commodity", "strength": "minor", "lasting": true},
		],
		"negative": [
			{"text": "Harbor Foods flags input-cost pressure into the next quarter.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "Harbor Foods recalls a limited SKU after a quality check.", "category": "product", "strength": "major", "lasting": false},
			{"text": "Analyst trims Harbor Foods on promotional intensity.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Whispers of retailer destocking hitting Harbor Foods.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Retailers are said to be pressing Harbor Foods on price.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Harbor Foods is offered as consumer names fade on traffic chatter.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"QBIT": {
		"positive": [
			{"text": "Street chatter: Qubit Labs named a dark-horse AI pick.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Qubit Labs posts a surprise research milestone.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Hot money piles into Qubit Labs on quantum chatter.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Analyst initiates Qubit Labs at Overweight.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "A partner lab is said to corroborate a Qubit Labs metric.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Qubit Labs is said to have a cleaner cash window than feared.", "category": "earnings", "strength": "minor", "lasting": true},
		],
		"negative": [
			{"text": "Whispers of a funding squeeze at Qubit Labs.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Qubit Labs delays a key lab demonstration.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Analyst flags dilution risk at Qubit Labs.", "category": "analyst", "strength": "moderate", "lasting": false},
			{"text": "Traders fade Qubit Labs after the morning squeeze.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A rival notes holes in a Qubit Labs demo claim.", "category": "product", "strength": "major", "lasting": true},
			{"text": "Qubit Labs looks crowded after the quantum squeeze.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
}

const COMPANY_NEWS_EXTRA := {
	"ALPH": {
		"positive": [
			{"text": "A CIO survey names Alpha Technologies among preferred refresh vendors.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Alpha Technologies is said to be lifting capex commentary on the quiet.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "Options skew turns bid in Alpha Technologies after a two-day washout.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Asia channel checks on Alpha Technologies come in firmer than the street had.", "category": "earnings", "strength": "moderate", "lasting": false},
			{"text": "Index desks are said to be covering a short in Alpha Technologies into the close.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A peer miss sends a relative bid into Alpha Technologies.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "A tax note is said to be hanging over an Alpha Technologies foreign unit.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "Alpha Technologies option vol spikes as the name looks crowded again.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Channel checks in Europe on Alpha Technologies come in mixed.", "category": "earnings", "strength": "minor", "lasting": false},
			{"text": "A large holder is said to have trimmed Alpha Technologies into strength.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Capex skepticism hangs over Alpha Technologies after a peer cut.", "category": "industry", "strength": "minor", "lasting": true},
			{"text": "Alpha Technologies underperforms the board on light, no-news flow.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "Merchant power prints lift Green Energy Corp versus the energy group.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "Tax-equity chatter turns constructive for Green Energy Corp.", "category": "regulatory", "strength": "minor", "lasting": true},
			{"text": "A PPA roll is said to be pricing better than Green Energy Corp guided.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "REC prices firm — Green Energy Corp catches a bid with the complex.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "A regional utility is said to have asked Green Energy Corp for more capacity.", "category": "product", "strength": "moderate", "lasting": false},
		],
		"negative": [
			{"text": "Community opposition is said to be slowing a Green Energy Corp permit.", "category": "regulatory", "strength": "moderate", "lasting": true},
			{"text": "Merchant power fades — Green Energy Corp is offered with the group.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "Tax-equity spreads are said to have widened on Green Energy Corp names.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "A weather miss knocks generation assumptions for Green Energy Corp.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "Green Energy Corp underperforms on a quiet tape with no fresh print.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "A freight print eases — North Mining Ltd catches a bid with bulk.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "North Mining Ltd is said to have a cleaner cost-per-tonne print internally.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "China restocking chatter lifts North Mining Ltd with the miners.", "category": "commodity", "strength": "moderate", "lasting": false},
			{"text": "A local permit is said to have cleared for North Mining Ltd without drama.", "category": "regulatory", "strength": "minor", "lasting": true},
			{"text": "North Mining Ltd outperforms a soft materials tape on dip-buying.", "category": "rumor", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Freight rates bite — North Mining Ltd is offered with the bulk complex.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "A labor note is said to be hanging over a North Mining Ltd shift roster.", "category": "product", "strength": "minor", "lasting": false},
			{"text": "Inventory data in China weigh on North Mining Ltd with the miners.", "category": "commodity", "strength": "moderate", "lasting": false},
			{"text": "North Mining Ltd slips as the dollar firms and metals fade.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "Cost inflation chatter hangs over North Mining Ltd with no new guide.", "category": "earnings", "strength": "minor", "lasting": true},
		],
	},
	"HELX": {
		"positive": [
			{"text": "Helix Biotech is said to have a cleaner cash window than the street had.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "A conference abstract is said to be constructive for Helix Biotech.", "category": "product", "strength": "minor", "lasting": false},
			{"text": "Biotech ETFs bid — Helix Biotech catches a ride with the group.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Helix Biotech option flow turns bid after a two-day washout.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A KOL note on Helix Biotech is said to read less cautious than feared.", "category": "analyst", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Helix Biotech is offered as biotech ETFs dump into the close.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A financing window is said to look tighter for Helix Biotech.", "category": "earnings", "strength": "moderate", "lasting": false},
			{"text": "Helix Biotech vol spikes on light tape with no new data.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A peer safety print knocks Helix Biotech with the group.", "category": "industry", "strength": "moderate", "lasting": false},
			{"text": "Street chatter: Helix Biotech looks crowded after the squeeze.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"RETL": {
		"positive": [
			{"text": "Card data is said to be firmer in a Redline Retail category.", "category": "earnings", "strength": "minor", "lasting": false},
			{"text": "Redline Retail outperforms as money rotates into defensives.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A vendor is said to have given Redline Retail better terms on a SKU.", "category": "product", "strength": "minor", "lasting": true},
			{"text": "Weather looks friendlier for Redline Retail weekend traffic.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Redline Retail is bid as a peer's promo war looks less intense.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Card data is said to be softer in a Redline Retail region.", "category": "earnings", "strength": "minor", "lasting": false},
			{"text": "A shrink note hangs over Redline Retail with no new guide.", "category": "earnings", "strength": "minor", "lasting": false},
			{"text": "Redline Retail is offered as money rotates out of defensives.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "Weather looks unfriendly for Redline Retail weekend traffic.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A landlord is said to be pressing Redline Retail on a lease roll.", "category": "product", "strength": "minor", "lasting": false},
		],
	},
	"CYBR": {
		"positive": [
			{"text": "A breach note at a peer sends flow into CyberNest Inc.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "CyberNest Inc is said to have a cleaner billings mix this month.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "Federal budget chatter turns constructive for CyberNest Inc.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "CyberNest Inc option flow turns bid after a quiet two days.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A channel partner is said to have added CyberNest Inc to a bundle.", "category": "product", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Budget-freeze chatter hangs over CyberNest Inc government names.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "CyberNest Inc is offered as security names fade with growth.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A competitor is said to have undercut CyberNest Inc on a bake-off.", "category": "product", "strength": "moderate", "lasting": false},
			{"text": "CyberNest Inc vol spikes on light tape with no award print.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Collections chatter turns mixed at CyberNest Inc.", "category": "earnings", "strength": "minor", "lasting": false},
		],
	},
	"AERO": {
		"positive": [
			{"text": "Aether Aerospace is bid as defense ETFs catch a flow day.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A supplier is said to have cleared a part for Aether Aerospace.", "category": "product", "strength": "minor", "lasting": true},
			{"text": "Export-license chatter turns constructive for Aether Aerospace.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "Aether Aerospace outperforms a soft industrials tape.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Aftermarket commentary is said to be firm at Aether Aerospace.", "category": "earnings", "strength": "minor", "lasting": true},
		],
		"negative": [
			{"text": "A labor note hangs over an Aether Aerospace plant with no new guide.", "category": "product", "strength": "minor", "lasting": false},
			{"text": "Aether Aerospace is offered as defense flow fades into the close.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Export-license chatter turns cautious for Aether Aerospace.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "Titanium prices bite — Aether Aerospace slips with the group.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "Aether Aerospace underperforms on a quiet industrials tape.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"BANK": {
		"positive": [
			{"text": "Curve steepener chatter bids Bastion Bank with the banks.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "Bastion Bank is said to have a quieter charge-off month internally.", "category": "earnings", "strength": "minor", "lasting": true},
			{"text": "A capital-markets day is said to be landing cleaner for Bastion Bank.", "category": "analyst", "strength": "minor", "lasting": false},
			{"text": "Bastion Bank outperforms as money rotates into financials.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Deposit-beta chatter looks less ugly for Bastion Bank than peers.", "category": "earnings", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Curve flattener chatter knocks Bastion Bank with the banks.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A CRE pocket is said to look mixed at Bastion Bank with no new print.", "category": "earnings", "strength": "moderate", "lasting": false},
			{"text": "Bastion Bank is offered as financials fade with rates.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Regulatory-exam chatter hangs over Bastion Bank on light tape.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "Bastion Bank underperforms a firm bank tape — no news, just flow.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"FOOD": {
		"positive": [
			{"text": "Commodity inputs ease — Harbor Foods catches a bid with the group.", "category": "commodity", "strength": "minor", "lasting": true},
			{"text": "A grocer is said to have given Harbor Foods more shelf on a SKU.", "category": "product", "strength": "minor", "lasting": true},
			{"text": "Harbor Foods outperforms as money hides in staples.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "Export chatter turns constructive for a Harbor Foods category.", "category": "earnings", "strength": "minor", "lasting": false},
			{"text": "Harbor Foods is bid after a peer's promo intensity looks less hot.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Commodity inputs firm — Harbor Foods is offered with the group.", "category": "commodity", "strength": "minor", "lasting": true},
			{"text": "A grocer is said to have cut a Harbor Foods SKU on the shelf.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Harbor Foods is offered as money leaves staples for cyclicals.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A logistics snarl is said to be delaying a Harbor Foods DC.", "category": "product", "strength": "minor", "lasting": false},
			{"text": "Harbor Foods underperforms a firm consumer tape — just flow.", "category": "rumor", "strength": "minor", "lasting": false},
		],
	},
	"QBIT": {
		"positive": [
			{"text": "A grant window is said to have opened for Qubit Labs-style names.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "Qubit Labs is bid as speculative flow returns to the board.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A hiring note is said to look healthier at Qubit Labs than feared.", "category": "earnings", "strength": "minor", "lasting": false},
			{"text": "Qubit Labs option flow turns bid after a two-day washout.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "A university paper is said to cite a Qubit Labs method in passing.", "category": "product", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "A grant window is said to have slipped for Qubit Labs-style names.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "Qubit Labs is offered as speculative flow leaves the board.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A lockup-expiry note hangs over Qubit Labs with no company print.", "category": "rumor", "strength": "moderate", "lasting": false},
			{"text": "Qubit Labs vol spikes on light tape — still no demo print.", "category": "rumor", "strength": "minor", "lasting": false},
			{"text": "Cash-burn chatter turns mixed at Qubit Labs.", "category": "earnings", "strength": "minor", "lasting": true},
		],
	},
}

const FLOW_POSITIVE: Array[Dictionary] = [
	{"text": "Intraday: %s catches a relative bid versus the rest of the board.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Desk note: %s looks less crowded after the washout.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Block desks are said to be covering in %s into the afternoon.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "A quiet tape still bids %s on residual dip-buying.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Pairs traders are said to be long %s versus a weaker peer.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Intraday: %s holds the morning range while the board chops.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Gamma desks bid %s as short-dated vol cheapens.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "A systematic bid is said to have hit %s on the last rebalance.", "category": "rumor", "strength": "minor", "lasting": false},
]

const FLOW_NEGATIVE: Array[Dictionary] = [
	{"text": "Intraday: %s lags the board on light, no-news flow.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Desk note: %s looks heavy after a crowded morning.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Block desks are said to be distributing %s into strength.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "A quiet tape still offers %s on residual profit-taking.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Pairs traders are said to be short %s versus a firmer peer.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Intraday: %s loses the morning range while the board chops.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "Gamma desks offer %s as short-dated vol cheapens the wrong way.", "category": "rumor", "strength": "minor", "lasting": false},
	{"text": "A systematic offer is said to have hit %s on the last rebalance.", "category": "rumor", "strength": "minor", "lasting": false},
]

const PREMARKET_COMPANY := {
	"ALPH": {
		"positive": [
			{"text": "PREMARKET: Alpha Technologies beats quarterly earnings and raises guidance.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Alpha Technologies reports record annual revenue.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Alpha Technologies says cloud bookings tracked ahead overnight.", "category": "product", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Alpha Technologies misses quarterly earnings and cuts outlook.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Alpha Technologies issues a profit warning before the open.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Alpha Technologies flags softer enterprise demand into the print.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
	},
	"GRNE": {
		"positive": [
			{"text": "PREMARKET: Green Energy Corp beats earnings on strong project pipeline.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Green Energy Corp raises full-year guidance.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Green Energy Corp says a storage project is nearer commissioning.", "category": "product", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Green Energy Corp misses earnings as subsidies disappoint.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Green Energy Corp slashes annual production forecast.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Green Energy Corp warns a commissioning date may slip.", "category": "product", "strength": "moderate", "lasting": true},
		],
	},
	"NMIN": {
		"positive": [
			{"text": "PREMARKET: North Mining Ltd posts better-than-expected quarterly results.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: North Mining Ltd lifts annual output guidance.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: North Mining Ltd is said to be near an offtake extension.", "category": "commodity", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: North Mining Ltd misses earnings on weaker commodity prices.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: North Mining Ltd cuts annual production targets.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: North Mining Ltd flags a pit disruption into the open.", "category": "product", "strength": "moderate", "lasting": true},
		],
	},
	"HELX": {
		"positive": [
			{"text": "PREMARKET: Helix Biotech beats estimates after a clean trial update.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Helix Biotech raises pipeline commentary before the open.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Helix Biotech says a filing window still looks intact.", "category": "regulatory", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Helix Biotech misses as a trial delay hits the print.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Helix Biotech issues a cautionary note on a key study.", "category": "product", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Helix Biotech flags extra data may be needed for the file.", "category": "regulatory", "strength": "moderate", "lasting": true},
		],
	},
	"RETL": {
		"positive": [
			{"text": "PREMARKET: Redline Retail beats quarterly sales and holds margins.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Redline Retail lifts full-year traffic commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Redline Retail says holiday traffic is tracking ahead.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Redline Retail misses as traffic turns softer.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Redline Retail cuts a near-term margin outlook.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Redline Retail warns promotions may run hotter into the print.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
	},
	"CYBR": {
		"positive": [
			{"text": "PREMARKET: CyberNest Inc beats on a surge in security bookings.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: CyberNest Inc raises full-year ARR commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: CyberNest Inc says a bake-off is going its way.", "category": "product", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: CyberNest Inc misses as deal slip hits the quarter.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: CyberNest Inc warns of a slower government pipeline.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: CyberNest Inc flags a protest hanging over an award.", "category": "regulatory", "strength": "moderate", "lasting": true},
		],
	},
	"AERO": {
		"positive": [
			{"text": "PREMARKET: Aether Aerospace beats on stronger deliveries.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Aether Aerospace lifts backlog commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Aether Aerospace says a program is moving into rate production.", "category": "product", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Aether Aerospace misses as a program slips.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Aether Aerospace cuts a near-term delivery range.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Aether Aerospace flags a quality hold on a lot.", "category": "product", "strength": "moderate", "lasting": true},
		],
	},
	"BANK": {
		"positive": [
			{"text": "PREMARKET: Bastion Bank posts a better-than-expected NII print.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Bastion Bank lifts its capital-return outlook.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Bastion Bank says credit trends look cleaner than billed.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Bastion Bank misses as provisions jump.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Bastion Bank warns of hotter deposit costs.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Bastion Bank flags a pocket of consumer credit looking worse.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
	},
	"FOOD": {
		"positive": [
			{"text": "PREMARKET: Harbor Foods beats on volume and mix.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Harbor Foods lifts grocery-channel commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Harbor Foods says input costs are easing faster than billed.", "category": "earnings", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Harbor Foods misses as input costs bite.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Harbor Foods trims a near-term volume guide.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Harbor Foods flags a limited recall into the open.", "category": "product", "strength": "moderate", "lasting": false},
		],
	},
	"QBIT": {
		"positive": [
			{"text": "PREMARKET: Qubit Labs beats on a research milestone and contract chatter.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Qubit Labs raises cash-runway commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
			{"text": "PREMARKET: Qubit Labs says lab metrics are tracking ahead of a demo.", "category": "product", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "PREMARKET: Qubit Labs misses as a demo slips and costs run hot.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Qubit Labs flags a tighter funding window.", "category": "earnings", "strength": "major", "lasting": true},
			{"text": "PREMARKET: Qubit Labs warns a public demo may slip.", "category": "product", "strength": "moderate", "lasting": true},
		],
	},
}

const INDUSTRY_NEWS := {
	"Technology": {
		"positive": [
			{"text": "Tech sector: AI spending forecasts are raised across the group.", "category": "product", "strength": "moderate", "lasting": true},
			{"text": "Chip demand firms — technology names catch a bid.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Cloud spend chatter turns constructive across technology names.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "A CIO budget thaw rumor bids technology names.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Semiconductor foundry chatter turns constructive across the tech group.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Tech sector: enterprise software demand looks softer.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Growth-tech selling hits the tape after a crowded rally.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Hardware supply notes weigh on the technology group.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A CIO budget freeze rumor knocks technology names.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Semiconductor foundry chatter turns mixed across the tech group.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"Energy": {
		"positive": [
			{"text": "Energy complex: power-price strength lifts the group.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Clean-energy policy chatter turns constructive.", "category": "regulatory", "strength": "moderate", "lasting": true},
			{"text": "Grid-storage awards chatter lifts the energy group.", "category": "industry", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Energy complex: subsidy reviews weigh on the group.", "category": "regulatory", "strength": "major", "lasting": true},
			{"text": "Power-price softness knocks energy names.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "Interconnection delays weigh on the energy complex.", "category": "regulatory", "strength": "moderate", "lasting": true},
		],
	},
	"Materials": {
		"positive": [
			{"text": "Materials: miners catch a bid as industrial demand steadies.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Metals desks turn constructive on bulk commodities.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "Offtake chatter lifts the miners into the session.", "category": "commodity", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Materials: industrial demand worries hit the miners.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Mining names slip as inventory data disappoints.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "A pit-disruption note weighs on the materials group.", "category": "industry", "strength": "minor", "lasting": false},
		],
	},
	"Commodities": {
		"positive": [
			{"text": "Commodity complex rallies — energy and metals both bid.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Risk-on in commodities as the dollar eases.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "A supply scare bids the commodity complex.", "category": "commodity", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Broad commodity selloff hits energy and materials.", "category": "commodity", "strength": "moderate", "lasting": true},
			{"text": "Commodity tape turns heavy into the afternoon.", "category": "commodity", "strength": "minor", "lasting": false},
			{"text": "A demand scare dumps the commodity complex.", "category": "commodity", "strength": "moderate", "lasting": true},
		],
	},
	"Growth": {
		"positive": [
			{"text": "Growth rotation: high-duration names catch a bid.", "category": "macro", "strength": "moderate", "lasting": true},
			{"text": "Risk appetite returns to growth and speculative names.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A cool data leak supercharges the growth bid.", "category": "macro", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Growth unwind: traders cut duration and speculative exposure.", "category": "macro", "strength": "moderate", "lasting": true},
			{"text": "Crowded growth trades get squeezed on the offer.", "category": "macro", "strength": "minor", "lasting": false},
			{"text": "A hot data leak torches the growth trade.", "category": "macro", "strength": "moderate", "lasting": true},
		],
	},
	"Healthcare": {
		"positive": [
			{"text": "Healthcare: biotech desks bid the group after a clean data tape.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Pipeline chatter turns constructive across healthcare names.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Filing-window chatter bids the healthcare group.", "category": "regulatory", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Healthcare: risk-off hits the biotech complex after mixed data.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Policy chatter weighs on healthcare multiples.", "category": "regulatory", "strength": "minor", "lasting": false},
			{"text": "A safety-review note weighs on the healthcare group.", "category": "industry", "strength": "moderate", "lasting": true},
		],
	},
	"Consumer": {
		"positive": [
			{"text": "Consumer: traffic and mix look firmer across the group.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Defensive consumer names catch a bid as the tape turns cautious.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Holiday traffic chatter turns constructive across consumer names.", "category": "industry", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Consumer: promotional intensity hits margins across the group.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Traffic worries knock consumer names.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A cold retail print weighs on the consumer group.", "category": "macro", "strength": "moderate", "lasting": true},
		],
	},
	"Industrials": {
		"positive": [
			{"text": "Industrials: backlog commentary turns constructive across the group.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Defense and aerospace names catch a bid on contract flow.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Rate-production chatter lifts the industrials group.", "category": "industry", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Industrials: supply-chain slips weigh on the group.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Order-book worries knock industrial names.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A quality-hold note weighs on industrials.", "category": "industry", "strength": "moderate", "lasting": true},
		],
	},
	"Financials": {
		"positive": [
			{"text": "Financials: net-interest commentary firms across the banks.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Credit desks turn constructive on the bank group.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "Capital-return chatter bids the financials group.", "category": "industry", "strength": "moderate", "lasting": true},
		],
		"negative": [
			{"text": "Financials: provision chatter weighs on the bank group.", "category": "industry", "strength": "moderate", "lasting": true},
			{"text": "Deposit-cost worries knock financial names.", "category": "industry", "strength": "minor", "lasting": false},
			{"text": "A hotter credit pocket weighs on the banks.", "category": "industry", "strength": "moderate", "lasting": true},
		],
	},
}

const MARKET_NEWS := {
	"positive": [
		{"text": "Intraday: buyers step back in across the tape.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Desk note: dip-buying interest is returning.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Soft landing print lifts risk appetite market-wide.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "Liquidity returns — the whole tape catches a bid.", "category": "macro", "strength": "moderate", "lasting": false},
		{"text": "A cooler inflation leak lifts risk appetite market-wide.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "Intraday: duration catches a bid after a quiet data window.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "A modest payroll leak lifts risk appetite without a full rotation.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Desk note: cash on the sidelines is said to be leaking back into the tape.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Intraday: the dollar eases and the whole board catches a bid.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Breadth improves — more names participate in the bounce.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "A quiet Fed window lets dip-buyers work the tape.", "category": "macro", "strength": "minor", "lasting": false},
	],
	"negative": [
		{"text": "Intraday: risk-off tone spreads across the market.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Desk note: traders reduce exposure into the close.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Hawkish shock knocks the whole market lower.", "category": "macro", "strength": "major", "lasting": true},
		{"text": "Liquidity thins — selling pressure hits every name.", "category": "macro", "strength": "moderate", "lasting": false},
		{"text": "A hotter inflation leak knocks the whole tape.", "category": "macro", "strength": "major", "lasting": true},
		{"text": "Intraday: duration is cut after a noisy data window.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "A modest payroll leak knocks risk without a full unwind.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Desk note: cash is said to be leaving the tape into the close.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Intraday: the dollar firms and the whole board is offered.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "Breadth deteriorates — fewer names hold the bounce.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "A noisy Fed window keeps dip-buyers on the sidelines.", "category": "macro", "strength": "minor", "lasting": false},
	],
}

const MARKET_PREMARKET := {
	"positive": [
		{"text": "PREMARKET: Futures jump after overnight economic data.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "PREMARKET: Risk appetite returns after a quiet overnight session.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "PREMARKET: Futures jump as overnight inflation chatter comes in cooler.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "PREMARKET: Asia closes firmer — futures gap with the overnight bid.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "PREMARKET: A quiet overnight window lets futures grind higher.", "category": "macro", "strength": "minor", "lasting": false},
	],
	"negative": [
		{"text": "PREMARKET: Futures slip as overnight data disappoints.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "PREMARKET: Cautious tape after weak global sentiment overnight.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "PREMARKET: Futures slip as overnight inflation chatter comes in hotter.", "category": "macro", "strength": "moderate", "lasting": true},
		{"text": "PREMARKET: Asia closes softer — futures gap with the overnight offer.", "category": "macro", "strength": "minor", "lasting": false},
		{"text": "PREMARKET: A noisy overnight window keeps futures heavy into the bell.", "category": "macro", "strength": "minor", "lasting": false},
	],
}


var company_hits: Dictionary = {}
var calendar_day: int = 0
var last_texts: PackedStringArray = PackedStringArray()
var used_day: Dictionary = {}
const RECENT_CAP := 48
const REPEAT_DAYS := 2


func generate_premarket(stocks: Array[Stock], session_time: String, avoid_subjects: Array[String] = []) -> Array[NewsEvent]:
	company_hits.clear()
	var events: Array[NewsEvent] = []
	var featured: Stock = _pick_company_stock(stocks, avoid_subjects)
	events.append(_make_company_event(featured, session_time, true))

	if randf() < 0.55:
		if randf() < 0.4:
			events.append(_make_industry_event(stocks, session_time, true))
		else:
			events.append(_make_company_event(_pick_company_stock(stocks, avoid_subjects), session_time, true))

	if randf() < 0.4:
		events.append(_make_market_event(stocks, session_time, true))

	return events


func generate_intraday(stocks: Array[Stock], session_time: String, avoid_subjects: Array[String] = []) -> NewsEvent:
	var roll := randf()
	if roll < 0.08:
		return _generate_surprise(_pick_company_stock(stocks, avoid_subjects), session_time)
	if roll < 0.28:
		return _make_industry_event(stocks, session_time, false)
	if roll < 0.46:
		return _make_market_event(stocks, session_time, false)
	return _make_company_event(_pick_company_stock(stocks, avoid_subjects), session_time, false)


func generate_open_bell(session_time: String) -> NewsEvent:
	return NewsEvent.new(
		session_time,
		"Market open. Use the premarket tape — then try to beat the market.",
		[],
		0.0,
		0.0,
		0,
		false,
		false,
		"general",
		"system"
	)


func _make_company_event(stock: Stock, session_time: String, premarket: bool) -> NewsEvent:
	var is_positive := randf() > (0.42 if premarket else 0.48)
	var pack: Dictionary = _company_templates(stock, premarket)
	var item: Dictionary = _pick_item(pack, is_positive)
	return _from_item(item, session_time, [stock.symbol], is_positive, premarket, "company", "")


func _make_industry_event(stocks: Array[Stock], session_time: String, premarket: bool, _avoid_subjects: Array[String] = []) -> NewsEvent:
	var keys: Array[String] = _industry_keys_for(stocks)
	if keys.is_empty():
		return _make_market_event(stocks, session_time, premarket)
	var industry: String = keys[randi() % keys.size()]
	var names: Array[String] = _symbols_for_industry(stocks, industry)
	if names.is_empty():
		return _make_market_event(stocks, session_time, premarket)
	var is_positive := randf() > 0.48
	var item: Dictionary = _pick_item(INDUSTRY_NEWS[industry], is_positive)
	var headline: String = str(item["text"])
	if premarket and not headline.begins_with("PREMARKET"):
		headline = "PREMARKET: " + headline
	var event := _from_item(item, session_time, names, is_positive, premarket, "industry", industry)
	event.headline = headline
	return event


func _make_market_event(stocks: Array[Stock], session_time: String, premarket: bool) -> NewsEvent:
	var is_positive := randf() > 0.5
	var pool: Dictionary = MARKET_PREMARKET if premarket else MARKET_NEWS
	var item: Dictionary = _pick_item(pool, is_positive)
	var names: Array[String] = []
	for stock in stocks:
		names.append(stock.symbol)
	return _from_item(item, session_time, names, is_positive, premarket, "market", "")


func _generate_surprise(stock: Stock, session_time: String) -> NewsEvent:
	var is_positive := randf() > 0.5
	var headlines: PackedStringArray
	if is_positive:
		headlines = PackedStringArray([
			"BREAKING: unexpected upgrade hits %s mid-session." % stock.company_name,
			"BREAKING: a surprise contract leak hits %s mid-session." % stock.company_name,
			"BREAKING: a buy-side note lifts %s mid-session." % stock.company_name,
			"BREAKING: unusual call buying hits %s mid-session." % stock.company_name,
			"BREAKING: a peer print sends a relative bid into %s." % stock.company_name,
		])
	else:
		headlines = PackedStringArray([
			"BREAKING: unexpected downgrade hits %s mid-session." % stock.company_name,
			"BREAKING: a surprise cut hits %s mid-session." % stock.company_name,
			"BREAKING: a sell-side note knocks %s mid-session." % stock.company_name,
			"BREAKING: unusual put buying hits %s mid-session." % stock.company_name,
			"BREAKING: a peer print sends a relative offer into %s." % stock.company_name,
		])
	var headline: String = _pick_fresh_text(headlines)
	var item := {
		"text": headline,
		"category": "analyst",
		"strength": "major",
		"lasting": randf() < 0.45,
	}
	_remember(headline)
	return _from_item(item, session_time, [stock.symbol], is_positive, false, "company", "")


func make_from_item(
	item: Dictionary,
	session_time: String,
	symbols: Array[String],
	is_positive: bool,
	premarket: bool,
	scope: String,
	industry: String
) -> NewsEvent:
	return _from_item(item, session_time, symbols, is_positive, premarket, scope, industry)


func symbols_for_industry(stocks: Array[Stock], industry: String) -> Array[String]:
	return _symbols_for_industry(stocks, industry)


func _pick_company_stock(stocks: Array[Stock], avoid_subjects: Array[String] = []) -> Stock:
	var eligible: Array[Stock] = []
	for stock in stocks:
		if stock.is_listed() and not avoid_subjects.has(stock.symbol):
			eligible.append(stock)
	if eligible.is_empty():
		for stock in stocks:
			if stock.is_listed():
				eligible.append(stock)
	if eligible.is_empty():
		eligible = stocks
	var lowest: int = 9999
	for stock in eligible:
		lowest = mini(lowest, int(company_hits.get(stock.symbol, 0)))
	var pool: Array[Stock] = []
	for stock in eligible:
		if int(company_hits.get(stock.symbol, 0)) <= lowest:
			pool.append(stock)
	var picked: Stock = pool[randi() % pool.size()]
	company_hits[picked.symbol] = int(company_hits.get(picked.symbol, 0)) + 1
	return picked


func _pick_unrelated_stock(stocks: Array[Stock], _avoid_subjects: Array[String]) -> Stock:
	return _pick_company_stock(stocks)


func _from_item(
	item: Dictionary,
	session_time: String,
	symbols: Array[String],
	is_positive: bool,
	premarket: bool,
	scope: String,
	industry: String
) -> NewsEvent:
	var strength: String = str(item.get("strength", "moderate"))
	var lasting: bool = bool(item.get("lasting", false))
	var category: String = str(item.get("category", "general"))
	var sentiment: float = 1.0 if is_positive else -1.0
	var impact: float = _roll_magnitude(strength, premarket, scope) * sentiment
	var duration: int = _roll_duration(strength, lasting)
	var is_major: bool = strength == "major" or bool(item.get("existential", false))
	var event := NewsEvent.new(
		session_time,
		str(item["text"]),
		symbols,
		sentiment,
		impact,
		duration,
		is_major,
		premarket,
		category,
		scope,
		strength,
		lasting,
		industry
	)
	event.existential = bool(item.get("existential", false))
	return event


func _roll_magnitude(strength: String, premarket: bool, scope: String) -> float:
	var profile: Dictionary = STRENGTH_RANGE.get(strength, STRENGTH_RANGE["moderate"])
	var band: Vector2 = profile["pre"] if premarket else profile["day"]
	var mag: float = randf_range(band.x, band.y)
	if scope == "industry":
		mag *= 0.85
	elif scope == "market":
		mag *= 0.72
	return mag


func _roll_duration(strength: String, lasting: bool) -> int:
	if lasting:
		match strength:
			"major":
				return randi_range(28, 48)
			"minor":
				return randi_range(16, 26)
			_:
				return randi_range(22, 36)
	match strength:
		"major":
			return randi_range(8, 14)
		"minor":
			return randi_range(3, 7)
		_:
			return randi_range(5, 11)


func _company_templates(stock: Stock, premarket: bool) -> Dictionary:
	var pool: Dictionary = PREMARKET_COMPANY if premarket else COMPANY_NEWS
	var pack: Dictionary
	if pool.has(stock.symbol):
		pack = _merge_sides(pool[stock.symbol], {} if premarket else COMPANY_NEWS_EXTRA.get(stock.symbol, {}))
	else:
		pack = _fallback_pack(stock, premarket)
	if not premarket:
		pack = _merge_sides(pack, _flow_pack(stock.company_name))
	return pack


func _industry_keys_for(stocks: Array[Stock]) -> Array[String]:
	var keys: Array[String] = []
	for stock in stocks:
		for industry in stock.industries:
			if INDUSTRY_NEWS.has(industry) and not keys.has(industry):
				keys.append(industry)
	return keys


func _symbols_for_industry(stocks: Array[Stock], industry: String) -> Array[String]:
	var names: Array[String] = []
	for stock in stocks:
		if stock.in_industry(industry):
			names.append(stock.symbol)
	return names


func _pick_item(company_templates: Dictionary, is_positive: bool) -> Dictionary:
	var side: String = "positive" if is_positive else "negative"
	var items: Array = company_templates[side]
	var fresh: Array = []
	for entry in items:
		var text: String = str(entry["text"]) if typeof(entry) == TYPE_DICTIONARY else str(entry)
		if not _is_blocked(text):
			fresh.append(entry)
	var picked: Variant
	if not fresh.is_empty():
		picked = fresh[randi() % fresh.size()]
	else:
		picked = _least_recent(items)
	if typeof(picked) == TYPE_DICTIONARY:
		_remember(str(picked.get("text", "")))
		return picked
	_remember(str(picked))
	return {"text": str(picked), "category": "general", "strength": "moderate", "lasting": false}


func _is_blocked(text: String) -> bool:
	if text.is_empty():
		return false
	if last_texts.has(text):
		return true
	var last: int = int(used_day.get(text, -99))
	return calendar_day - last < REPEAT_DAYS


func _remember(text: String) -> void:
	if text.is_empty():
		return
	last_texts.append(text)
	while last_texts.size() > RECENT_CAP:
		last_texts.remove_at(0)
	used_day[text] = calendar_day


func _least_recent(items: Array) -> Variant:
	var best: Variant = items[0]
	var best_day: int = 99999
	for entry in items:
		var text: String = str(entry["text"]) if typeof(entry) == TYPE_DICTIONARY else str(entry)
		var day: int = int(used_day.get(text, -99))
		if day < best_day:
			best_day = day
			best = entry
	return best


func _pick_fresh_text(headlines: PackedStringArray) -> String:
	var fresh: PackedStringArray = PackedStringArray()
	for line in headlines:
		if not _is_blocked(line):
			fresh.append(line)
	if fresh.is_empty():
		return headlines[randi() % headlines.size()]
	return fresh[randi() % fresh.size()]


func _merge_sides(base: Dictionary, extra: Dictionary) -> Dictionary:
	return {
		"positive": _concat_items(base.get("positive", []), extra.get("positive", [])),
		"negative": _concat_items(base.get("negative", []), extra.get("negative", [])),
	}


func _concat_items(a: Variant, b: Variant) -> Array:
	var out: Array = []
	if typeof(a) == TYPE_ARRAY:
		for item in a:
			out.append(item)
	if typeof(b) == TYPE_ARRAY:
		for item in b:
			out.append(item)
	return out


func _flow_pack(company_name: String) -> Dictionary:
	return {
		"positive": _format_flow(FLOW_POSITIVE, company_name),
		"negative": _format_flow(FLOW_NEGATIVE, company_name),
	}


func _format_flow(templates: Array[Dictionary], company_name: String) -> Array:
	var out: Array = []
	for item in templates:
		var copy: Dictionary = item.duplicate()
		copy["text"] = str(item["text"]) % company_name
		out.append(copy)
	return out


func _fallback_pack(stock: Stock, premarket: bool) -> Dictionary:
	var name: String = stock.company_name
	if premarket:
		return {
			"positive": [
				{"text": "PREMARKET: %s beats quarterly earnings." % name, "category": "earnings", "strength": "major", "lasting": true},
			],
			"negative": [
				{"text": "PREMARKET: %s misses quarterly earnings." % name, "category": "earnings", "strength": "major", "lasting": true},
			],
		}
	return {
		"positive": [
			{"text": "Analyst raises %s." % name, "category": "analyst", "strength": "minor", "lasting": false},
		],
		"negative": [
			{"text": "Analyst trims %s." % name, "category": "analyst", "strength": "minor", "lasting": false},
		],
	}
