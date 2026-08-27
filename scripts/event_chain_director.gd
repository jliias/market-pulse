class_name EventChainDirector
extends RefCounted

const MAX_ACTIVE := 2
const SKIP_CHANCE := {
	"follow_up": 0.24,
	"reaction": 0.34,
	"twist": 0.48,
	"resolution": 0.16,
}

const ARCS := {
	"alph_nexis": {
		"scope": "company",
		"subject": "ALPH",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Alpha Technologies announces the Nexis AI accelerator.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Alpha Technologies delays the Nexis AI accelerator.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: two hyperscalers are said to be testing Nexis.", "category": "product", "strength": "moderate", "lasting": true},
					{"text": "Follow-up: Alpha Technologies raises Nexis qualification commentary.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Nexis customers are said to be pushing out orders.", "category": "product", "strength": "moderate", "lasting": true},
					{"text": "Follow-up: street cuts Nexis shipment assumptions.", "category": "analyst", "strength": "moderate", "lasting": false},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: momentum desks pile into Alpha Technologies on the Nexis tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: fast money dumps Alpha Technologies after the Nexis headlines.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: Nexis yields come in better than the company billed.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: Nexis yields look worse than billed — street second-guesses the launch.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Alpha Technologies confirms Nexis is shipping in volume.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Alpha Technologies shelves the first Nexis production wave.", "category": "product", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"grne_subsidy": {
		"scope": "company",
		"subject": "GRNE",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Green Energy Corp says a new subsidy bill is moving in committee.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Green Energy Corp warns a key subsidy bill may be pulled.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: whip count improves for the Green Energy Corp subsidy language.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: the subsidy text for Green Energy Corp is being watered down.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: speculative flow chases Green Energy Corp on the policy tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Green Energy Corp gets sold as traders fade the policy rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a last-minute amendment restores the Green Energy Corp subsidy.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: the committee shelves the Green Energy Corp subsidy overnight.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the subsidy bill clears — Green Energy Corp keeps the support.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the subsidy effort dies — Green Energy Corp loses the support.", "category": "regulatory", "strength": "major", "lasting": true, "existential": true},
				],
			},
		},
	},
	"nmin_pit": {
		"scope": "company",
		"subject": "NMIN",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "North Mining Ltd reports a high-grade intercept at the north pit.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "North Mining Ltd reports a disruption at the north pit.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: North Mining Ltd lifts the pit's near-term output range.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: North Mining Ltd trims pit shipments while it investigates.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: miners bid North Mining Ltd as the pit story spreads.", "category": "commodity", "strength": "minor", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: North Mining Ltd slips as desks fade the pit headline.", "category": "commodity", "strength": "minor", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: the north pit comes back faster than North Mining Ltd guided.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: the north pit issue is wider than first reported.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: North Mining Ltd restores full pit operations and holds guidance.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: North Mining Ltd cuts full-year output after the pit setback.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"growth_rotation": {
		"scope": "industry",
		"subject": "GROWTH",
		"industry": "Growth",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Desks call a growth rotation: duration and speculative stocks are back in favor.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Desks warn a growth unwind is starting across high-duration stocks.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: growth-factor flows stay bid into the session.", "category": "macro", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: growth-factor selling persists as positioning stays crowded.", "category": "macro", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: growth stocks on the board catch the bid.", "category": "macro", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: growth stocks on the board are offered as duration gets cut.", "category": "macro", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a soft data print supercharges the growth bid.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a hot data print torches the growth trade.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the growth rotation holds — desks stay long duration.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the growth unwind is done — desks call the factor reset complete.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
		},
	},
	"helx_trial": {
		"scope": "company",
		"subject": "HELX",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Helix Biotech says a pivotal readout is coming in range.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Helix Biotech says a pivotal readout may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: investigators sound constructive on the Helix Biotech cohort.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: enrollment at Helix Biotech looks slower than billed.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: biotech flow chases Helix Biotech on the trial tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Helix Biotech is offered as desks fade the trial rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a subgroup look at Helix Biotech comes in cleaner than feared.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a safety flag at Helix Biotech is wider than first billed.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Helix Biotech confirms the trial met the primary endpoint.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Helix Biotech says the trial missed and the timeline is under review.", "category": "product", "strength": "major", "lasting": true, "existential": true},
				],
			},
		},
	},
	"cybr_contract": {
		"scope": "company",
		"subject": "CYBR",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "CyberNest Inc says it is in late talks on a large security award.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "CyberNest Inc warns a large security award may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: CyberNest Inc commentary on the award stays constructive.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: the CyberNest Inc award looks more competitive than billed.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: speculative flow chases CyberNest Inc on the contract tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: CyberNest Inc is sold as traders fade the award rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: CyberNest Inc is said to have the inside track after a bake-off.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a protest is said to be hanging over the CyberNest Inc award.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: CyberNest Inc confirms the multi-year security award.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: CyberNest Inc loses the award — the rumor dies.", "category": "product", "strength": "major", "lasting": true, "existential": true},
				],
			},
		},
	},
	"qbit_demo": {
		"scope": "company",
		"subject": "QBIT",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Qubit Labs teases a public quantum demo this month.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Qubit Labs warns the public quantum demo may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Qubit Labs says lab metrics are tracking ahead of the demo.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Qubit Labs trims demo commentary as calibration slips.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: hot money piles into Qubit Labs on the demo tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Qubit Labs is offered as traders fade the demo rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a partner lab corroborates the Qubit Labs metrics.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a rival notes holes in the Qubit Labs demo claims.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Qubit Labs completes the demo and holds the narrative.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Qubit Labs postpones the demo — the squeeze unwinds.", "category": "product", "strength": "major", "lasting": true, "existential": true},
				],
			},
		},
	},
	"nova_fleet": {
		"scope": "company",
		"subject": "NOVA",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Nova Mobility says a city fleet program is moving into rate production.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Nova Mobility warns a city fleet program may slip rate production.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Nova Mobility supplier commentary stays constructive.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: a battery partner is said to be the bottleneck at Nova Mobility.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: industrials bid Nova Mobility on the fleet tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Nova Mobility is offered as desks fade the fleet rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: the city is said to have lifted Nova Mobility's near-term slot.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a software hold is said to be hanging over a Nova Mobility lot.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Nova Mobility confirms rate production and holds deliveries.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Nova Mobility trims the delivery guide after the fleet slip.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"drft_launch": {
		"scope": "company",
		"subject": "DRFT",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Drift Interactive teases a flagship launch this month.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Drift Interactive warns the flagship launch may slip.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Drift Interactive says beta metrics are tracking ahead of launch.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Drift Interactive trims launch commentary as bugs pile up.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: hot money piles into Drift Interactive on the launch tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Drift Interactive is offered as traders fade the launch rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a platform partner features the Drift Interactive title on the storefront.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a rival notes holes in the Drift Interactive beta.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Drift Interactive ships the title and holds the player count.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Drift Interactive postpones the launch — the squeeze unwinds.", "category": "product", "strength": "major", "lasting": true, "existential": true},
				],
			},
		},
	},
	"hawkish_tape": {
		"scope": "market",
		"subject": "MARKET",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Leak: policymakers are more open to an easier stance than the street priced.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Leak: policymakers may stay tighter for longer than the street priced.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: overnight commentary stays dovish versus the leak.", "category": "macro", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: overnight commentary stays hawkish versus the leak.", "category": "macro", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: risk appetite returns across the tape.", "category": "macro", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: risk-off hits every stock after the policy leak.", "category": "macro", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: an official walk-back sounds easier than the original leak.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: an official walk-back sounds tighter than the original leak.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the official print lands dovish — the easier-policy story holds.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the official print lands hawkish — the tighter-policy story holds.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"alph_cloud": {
		"scope": "company",
		"subject": "ALPH",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Alpha Technologies says enterprise cloud bookings are tracking ahead.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Alpha Technologies warns enterprise cloud bookings may slip.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: two large accounts are said to be expanding Alpha Technologies deployments.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: CIOs are said to be stretching Alpha Technologies refresh cycles.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: growth desks bid Alpha Technologies on the cloud tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Alpha Technologies is offered as desks fade the cloud rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a hyperscaler is said to have lifted Alpha Technologies allocation.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a large customer is said to have paused an Alpha Technologies rollout.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Alpha Technologies confirms the cloud miss was noise and holds the outlook.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Alpha Technologies cuts cloud commentary — the demand scare sticks.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"grne_storage": {
		"scope": "company",
		"subject": "GRNE",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Green Energy Corp says a flagship storage project is nearing commissioning.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Green Energy Corp warns a flagship storage project may slip commissioning.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: interconnection chatter for Green Energy Corp turns constructive.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: interconnection delays are said to be hanging over Green Energy Corp.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: speculative flow chases Green Energy Corp on the project tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Green Energy Corp is sold as traders fade the project rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: Green Energy Corp gets an earlier grid slot than billed.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a supplier issue is said to be wider at Green Energy Corp.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Green Energy Corp commissions the storage project and holds guidance.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Green Energy Corp delays the project and trims the pipeline.", "category": "product", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"nmin_offtake": {
		"scope": "company",
		"subject": "NMIN",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "North Mining Ltd is said to be near a long-term offtake extension.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "North Mining Ltd warns a key offtake may be reopened.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: the buyer is said to want more tonnes from North Mining Ltd.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: the buyer is said to be pressing North Mining Ltd on price.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: miners bid North Mining Ltd as the offtake story spreads.", "category": "commodity", "strength": "minor", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: North Mining Ltd slips as desks fade the contract tape.", "category": "commodity", "strength": "minor", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a second offtaker is said to have joined the North Mining Ltd talks.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a rival is said to be undercutting North Mining Ltd on the same tonnes.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: North Mining Ltd extends the offtake and holds the volume guide.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: North Mining Ltd loses the offtake window and trims shipments.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"helx_fda": {
		"scope": "company",
		"subject": "HELX",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Helix Biotech says it has a clear path into a regulatory filing window.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Helix Biotech warns the filing window may slip after a regulator note.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Helix Biotech commentary on the filing stays constructive.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Helix Biotech is said to be gathering extra data for the file.", "category": "regulatory", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: biotech flow chases Helix Biotech on the filing tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Helix Biotech is offered as desks fade the filing rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a regulator meeting for Helix Biotech is said to have gone clean.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: Helix Biotech is said to have drawn a request for more data.", "category": "regulatory", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Helix Biotech files on time — the path holds.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Helix Biotech delays the file — the timeline is under review.", "category": "regulatory", "strength": "major", "lasting": true, "existential": true},
				],
			},
		},
	},
	"retl_holiday": {
		"scope": "company",
		"subject": "RETL",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Redline Retail says holiday traffic is tracking ahead of plan.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Redline Retail warns holiday traffic may come in light.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Redline Retail mix looks better than the traffic print implied.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Redline Retail is leaning harder on promotions than billed.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: defensive flow bids Redline Retail on the traffic tape.", "category": "rumor", "strength": "minor", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Redline Retail slips as desks fade the holiday rumor.", "category": "rumor", "strength": "minor", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a category beat at Redline Retail is wider than first billed.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: inventory at Redline Retail looks heavier than the company guided.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Redline Retail holds the holiday outlook after the traffic print.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Redline Retail cuts near-term sales after the traffic miss.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"aero_program": {
		"scope": "company",
		"subject": "AERO",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Aether Aerospace says a key program is moving into rate production.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Aether Aerospace warns a key program may slip rate production.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Aether Aerospace supplier commentary stays constructive.", "category": "product", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: a supplier is said to be the bottleneck at Aether Aerospace.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: industrials bid Aether Aerospace on the program tape.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Aether Aerospace is offered as desks fade the program rumor.", "category": "rumor", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: the customer is said to have lifted Aether Aerospace's near-term slot.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a quality hold is said to be hanging over an Aether Aerospace lot.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Aether Aerospace confirms rate production and holds deliveries.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Aether Aerospace trims the delivery guide after the program slip.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"bank_credit": {
		"scope": "company",
		"subject": "BANK",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Bastion Bank says credit trends look cleaner than the street billed.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Bastion Bank warns credit costs may run hotter than billed.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Bastion Bank deposit costs look more stable than feared.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: Bastion Bank is said to be paying up more for deposits.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: financials bid Bastion Bank on the credit tape.", "category": "rumor", "strength": "minor", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Bastion Bank slips as desks fade the credit rumor.", "category": "rumor", "strength": "minor", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a regulator note on Bastion Bank comes in quieter than feared.", "category": "regulatory", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a pocket of consumer credit at Bastion Bank looks worse than billed.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Bastion Bank holds provisions and lifts capital-return commentary.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Bastion Bank lifts provisions and trims the return outlook.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"food_costs": {
		"scope": "company",
		"subject": "FOOD",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Harbor Foods says input costs are easing faster than the street billed.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Harbor Foods warns input costs may stay hot into the next earnings.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: Harbor Foods mix in grocery looks firmer than volume implied.", "category": "earnings", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: retailers are said to be pressing Harbor Foods on price.", "category": "product", "strength": "moderate", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: defensive flow bids Harbor Foods on the cost tape.", "category": "rumor", "strength": "minor", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: Harbor Foods slips as desks fade the cost rumor.", "category": "rumor", "strength": "minor", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: Harbor Foods locks a lower private-label supply print.", "category": "product", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a limited Harbor Foods recall is wider than first billed.", "category": "product", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: Harbor Foods holds margins and lifts volume commentary.", "category": "earnings", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: Harbor Foods trims the margin outlook after the cost miss.", "category": "earnings", "strength": "major", "lasting": true},
				],
			},
		},
	},
	"consumer_traffic": {
		"scope": "industry",
		"subject": "CONSUMER",
		"industry": "Consumer",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Desks call a consumer bounce: traffic and mix look firmer across the group.", "category": "industry", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Desks warn a consumer squeeze: traffic looks light and promotions are rising.", "category": "industry", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: consumer-factor flows stay bid into the session.", "category": "industry", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: consumer stocks stay offered as traffic chatter stays soft.", "category": "industry", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: consumer stocks on the board catch the bid.", "category": "industry", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: consumer stocks on the board are offered as traffic fades.", "category": "industry", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a retail print comes in hotter than the consumer group priced.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a retail print comes in colder than the consumer group priced.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the consumer bounce holds — desks stay in the defensive stocks.", "category": "industry", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the consumer squeeze is done — desks call the traffic reset complete.", "category": "industry", "strength": "moderate", "lasting": true},
				],
			},
		},
	},
	"commodities_swing": {
		"scope": "industry",
		"subject": "COMMODITIES",
		"industry": "Commodities",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Commodity desks call a bid: metals and energy both look supported.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Commodity desks warn of a dump: metals and energy both look heavy.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: the dollar ease keeps the commodity bid intact.", "category": "commodity", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: inventory data keeps the commodity offer intact.", "category": "commodity", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: commodity stocks on the board catch the bid.", "category": "commodity", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: commodity stocks on the board are offered with the complex.", "category": "commodity", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a supply scare supercharges the commodity bid.", "category": "commodity", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a demand scare torches the commodity trade.", "category": "commodity", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the commodity bid holds — desks stay long the complex.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the commodity dump is done — desks call the reset complete.", "category": "commodity", "strength": "moderate", "lasting": true},
				],
			},
		},
	},
	"inflation_print": {
		"scope": "market",
		"subject": "MARKET",
		"industry": "",
		"stages": {
			"announcement": {
				"positive": [
					{"text": "Leak: the inflation print may come in cooler than the street priced.", "category": "macro", "strength": "moderate", "lasting": true},
				],
				"negative": [
					{"text": "Leak: the inflation print may come in hotter than the street priced.", "category": "macro", "strength": "moderate", "lasting": true},
				],
			},
			"follow_up": {
				"positive": [
					{"text": "Follow-up: overnight inflation chatter stays cooler versus the leak.", "category": "macro", "strength": "minor", "lasting": true},
				],
				"negative": [
					{"text": "Follow-up: overnight inflation chatter stays hotter versus the leak.", "category": "macro", "strength": "minor", "lasting": true},
				],
			},
			"reaction": {
				"positive": [
					{"text": "Market reaction: risk appetite returns as duration catches a bid.", "category": "macro", "strength": "moderate", "lasting": false},
				],
				"negative": [
					{"text": "Market reaction: risk-off hits every stock as duration is cut.", "category": "macro", "strength": "moderate", "lasting": false},
				],
			},
			"twist": {
				"positive": [
					{"text": "Unexpected: a core print looks even cooler than the headline leak.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Unexpected: a core print looks even hotter than the headline leak.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
			"resolution": {
				"positive": [
					{"text": "Resolution: the official inflation print lands cool — the risk-on story holds.", "category": "macro", "strength": "major", "lasting": true},
				],
				"negative": [
					{"text": "Resolution: the official inflation print lands hot — the risk-off story holds.", "category": "macro", "strength": "major", "lasting": true},
				],
			},
		},
	},
}

var active: Array[EventChain] = []
var cooldowns: Dictionary = {}
var calendar_day: int = 0
var news_generator: NewsGenerator


var last_tick: int = 0
var skip_premarket_chains: bool = false


func _init(p_generator: NewsGenerator) -> void:
	news_generator = p_generator


func reset() -> void:
	active.clear()
	cooldowns.clear()
	calendar_day = 0
	last_tick = 0
	skip_premarket_chains = false


func serialize() -> Dictionary:
	var chains: Array = []
	for chain in active:
		chains.append(chain.to_dict())
	return {
		"active": chains,
		"cooldowns": cooldowns.duplicate(),
	}


static func hook_from_save(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var saved_chains: Variant = (data as Dictionary).get("active", [])
	if typeof(saved_chains) != TYPE_ARRAY:
		return ""
	for item in saved_chains:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var line: String = _hook_from_dict(item)
		if not line.is_empty():
			return line
	return ""


func chain_by_arc_id(arc_id: String) -> EventChain:
	for chain in active:
		if chain.arc_id == arc_id:
			return chain
	return null


func note_related_news(event: NewsEvent, stocks: Dictionary) -> void:
	if event == null:
		return
	if event.scope == "system" and event.chain_id.is_empty() and event.drama_kind.is_empty() and not event.existential:
		return
	for chain in active:
		if not event.chain_id.is_empty() and event.chain_id == chain.arc_id:
			continue
		if _event_matches_chain(event, chain, stocks):
			chain.log_tape(event.headline, _topic_day(), event.timestamp)


func _topic_day() -> int:
	return maxi(calendar_day, 0) + 1


func _event_matches_chain(event: NewsEvent, chain: EventChain, stocks: Dictionary) -> bool:
	if not event.chain_id.is_empty():
		return event.chain_id == chain.arc_id
	match chain.scope:
		"company":
			if event.affected_symbols.has(chain.subject):
				return true
			var name: String = CompanyCatalog.display_name(chain.subject)
			return event.headline.contains(chain.subject) or (not name.is_empty() and event.headline.contains(name))
		"industry":
			if not chain.industry.is_empty() and event.industry == chain.industry:
				return true
			for symbol in event.affected_symbols:
				if not stocks.has(symbol):
					continue
				var stock: Stock = stocks[symbol]
				if stock.in_industry(chain.industry):
					return true
			return false
		_:
			return event.scope == "market"


func hook_line() -> String:
	for chain in active:
		var line: String = hook_text(chain)
		if not line.is_empty():
			return line
	return ""


func board_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for chain in active:
		if chain.pending.is_empty():
			continue
		var wipe: bool = chain.pending == "resolution" and chain.polarity < 0.0 and arc_is_existential(chain.arc_id)
		out.append({
			"arc_id": chain.arc_id,
			"subject": chain.subject,
			"scope": chain.scope,
			"industry": chain.industry,
			"stage": EventChain.display_stage(chain.pending),
			"pending": chain.pending,
			"wipe": wipe,
			"hook": hook_text(chain),
			"card_hook": card_hook(chain),
			"beats": chain.beat_log.duplicate(true),
			"polarity": chain.polarity,
		})
	return out


func card_hook(chain: EventChain) -> String:
	if chain.pending.is_empty():
		return ""
	if chain.pending == "resolution" and chain.polarity < 0.0 and arc_is_existential(chain.arc_id):
		return "Make-or-break tomorrow."
	return "Not finished yet."


func hook_text(chain: EventChain) -> String:
	if chain.pending.is_empty():
		return ""
	var stage: String = EventChain.display_stage(chain.pending)
	if chain.pending == "resolution" and chain.polarity < 0.0 and arc_is_existential(chain.arc_id):
		match chain.scope:
			"company":
				return "%s — resolution tomorrow. Make-or-break." % CompanyCatalog.display_name(chain.subject)
			_:
				return "Resolution tomorrow. Make-or-break."
	match chain.scope:
		"company":
			return "%s — %s still unresolved" % [CompanyCatalog.display_name(chain.subject), stage]
		"industry":
			var industry_name: String = chain.industry if not chain.industry.is_empty() else "Sector"
			return "%s story — %s still unresolved" % [industry_name, stage]
		_:
			return "Policy story — %s still unresolved" % stage


static func _hook_from_dict(item: Dictionary) -> String:
	var pending: String = str(item.get("pending", ""))
	if pending.is_empty():
		return ""
	var stage: String = EventChain.display_stage(pending)
	var scope: String = str(item.get("scope", "company"))
	var arc_id: String = str(item.get("arc_id", ""))
	if pending == "resolution" and float(item.get("polarity", 1.0)) < 0.0 and arc_is_existential(arc_id):
		if scope == "company":
			return "%s — resolution tomorrow. Make-or-break." % CompanyCatalog.display_name(str(item.get("subject", "")))
		return "Resolution tomorrow. Make-or-break."
	match scope:
		"company":
			return "%s — %s still unresolved" % [CompanyCatalog.display_name(str(item.get("subject", ""))), stage]
		"industry":
			var industry_name: String = str(item.get("industry", "Sector"))
			if industry_name.is_empty():
				industry_name = "Sector"
			return "%s story — %s still unresolved" % [industry_name, stage]
		_:
			return "Policy story — %s still unresolved" % stage


func deserialize(data: Dictionary) -> void:
	active.clear()
	cooldowns.clear()
	var saved_chains: Variant = data.get("active", [])
	if typeof(saved_chains) == TYPE_ARRAY:
		for item in saved_chains:
			if typeof(item) == TYPE_DICTIONARY:
				var chain: EventChain = EventChain.from_dict(item)
				if ARCS.has(chain.arc_id) and not chain.pending.is_empty():
					active.append(chain)
	var saved_cd: Variant = data.get("cooldowns", {})
	if typeof(saved_cd) == TYPE_DICTIONARY:
		for key in saved_cd:
			cooldowns[str(key)] = int(saved_cd[key])


func occupied_subjects() -> Array[String]:
	var names: Array[String] = []
	for chain in active:
		names.append(chain.subject)
	return names


func collect_premarket(stocks: Array[Stock], session_time: String) -> Array[NewsEvent]:
	last_tick = 0
	_prune_cooldowns()
	if skip_premarket_chains:
		skip_premarket_chains = false
		return []
	var events: Array[NewsEvent] = []
	var due: Array[EventChain] = []
	for chain in active:
		if _is_due_premarket(chain):
			due.append(chain)
	for chain in due:
		var event: NewsEvent = _fire(chain, stocks, session_time, true)
		if event != null:
			events.append(event)
		if events.size() >= 2:
			break
	if events.is_empty() and active.size() < MAX_ACTIVE and randf() < 0.16:
		var started: NewsEvent = try_start(stocks, session_time, true)
		if started != null:
			events.append(started)
	return events


func try_fire_due(stocks: Array[Stock], session_time: String, tick_count: int) -> NewsEvent:
	last_tick = tick_count
	_prune_cooldowns()
	var overdue: EventChain = _pick_due_intraday(tick_count)
	if overdue == null:
		return null
	var wait: int = tick_count - overdue.due_tick
	if wait >= 80 or randf() < 0.035:
		return _fire(overdue, stocks, session_time, false)
	return null


func try_intraday(stocks: Array[Stock], session_time: String, tick_count: int) -> NewsEvent:
	return try_fire_due(stocks, session_time, tick_count)


func try_away_beat(stocks: Array[Stock], session_time: String) -> NewsEvent:
	_prune_cooldowns()
	for chain in active:
		if chain.pending.is_empty():
			continue
		skip_premarket_chains = true
		return _fire(chain, stocks, session_time, true)
	if active.size() < MAX_ACTIVE and randf() < 0.28:
		var started: NewsEvent = try_start(stocks, session_time, true)
		if started != null:
			skip_premarket_chains = true
		return started
	return null


func try_start(stocks: Array[Stock], session_time: String, premarket: bool) -> NewsEvent:
	var arc_id: String = _pick_available_arc(stocks)
	if arc_id.is_empty():
		return null
	var spec: Dictionary = ARCS[arc_id]
	var chain := EventChain.new()
	chain.arc_id = arc_id
	chain.subject = str(spec["subject"])
	chain.scope = str(spec["scope"])
	chain.industry = str(spec["industry"])
	chain.polarity = 1.0 if randf() > 0.46 else -1.0
	chain.pending = "announcement"
	chain.started_day = calendar_day
	chain.due_day = calendar_day
	chain.due_tick = 0
	chain.prefer_premarket = premarket
	active.append(chain)
	return _fire(chain, stocks, session_time, premarket)


func on_session_end() -> void:
	var still_active: Array[EventChain] = []
	for chain in active:
		if chain.pending.is_empty():
			_start_cooldown(chain.arc_id)
			continue
		if chain.due_day <= calendar_day:
			chain.due_day = calendar_day + 1
			chain.prefer_premarket = randf() < 0.55
			chain.due_tick = 0 if chain.prefer_premarket else randi_range(18, 200)
		if calendar_day - chain.started_day >= 10 and chain.pending != "resolution":
			chain.pending = "resolution"
			chain.due_day = calendar_day + 1
			chain.prefer_premarket = true
			chain.due_tick = 0
		if calendar_day - chain.started_day >= 16:
			_start_cooldown(chain.arc_id)
			continue
		still_active.append(chain)
	active = still_active


func _is_due_premarket(chain: EventChain) -> bool:
	if chain.pending.is_empty() or chain.due_day != calendar_day:
		return false
	return chain.prefer_premarket or chain.due_tick <= 0


func _pick_due_intraday(tick_count: int) -> EventChain:
	for chain in active:
		if chain.pending.is_empty():
			continue
		if chain.due_day != calendar_day:
			continue
		if chain.prefer_premarket and tick_count < 40:
			continue
		if tick_count >= chain.due_tick:
			return chain
	return null


func _fire(chain: EventChain, stocks: Array[Stock], session_time: String, premarket: bool) -> NewsEvent:
	var stage: String = chain.pending
	if stage.is_empty() or not ARCS.has(chain.arc_id):
		return null
	var positive: bool = chain.polarity > 0.0
	if stage == "twist":
		if randf() < 0.72:
			positive = not positive
			chain.polarity = 1.0 if positive else -1.0
	var item: Dictionary = _stage_item(chain.arc_id, stage, positive)
	if item.is_empty():
		_advance(chain, stage)
		return null
	var symbols: Array[String] = _symbols_for_chain(chain, stocks)
	var event: NewsEvent = news_generator.make_from_item(
		item, session_time, symbols, positive, premarket, chain.scope, chain.industry
	)
	var headline: String = str(item["text"])
	if premarket and not headline.begins_with("PREMARKET"):
		headline = "PREMARKET: " + headline
	event.headline = headline
	event.attach_chain(chain.arc_id, stage)
	event.existential = bool(item.get("existential", false))
	chain.log_beat(stage, headline, _topic_day(), session_time)
	_advance(chain, stage)
	return event


func _advance(chain: EventChain, fired_stage: String) -> void:
	if not chain.fired.has(fired_stage):
		chain.fired.append(fired_stage)
	var next_stage: String = _choose_next(fired_stage, chain)
	if next_stage.is_empty():
		chain.pending = ""
		_start_cooldown(chain.arc_id)
		active.erase(chain)
		return
	chain.pending = next_stage
	_schedule(chain, fired_stage)


func _choose_next(from_stage: String, chain: EventChain) -> String:
	var start: int = EventChain.STAGE_ORDER.find(from_stage) + 1
	if start <= 0:
		start = 1
	var chosen: String = ""
	for i in range(start, EventChain.STAGE_ORDER.size()):
		var stage: String = EventChain.STAGE_ORDER[i]
		var chance: float = float(SKIP_CHANCE.get(stage, 0.0))
		if randf() < chance:
			if not chain.skipped.has(stage):
				chain.skipped.append(stage)
				chain.log_skip(stage, _topic_day())
			continue
		chosen = stage
		break
	if chosen.is_empty() and from_stage != "resolution" and randf() < 0.55:
		return "resolution"
	return chosen


func _schedule(chain: EventChain, from_stage: String) -> void:
	var same_day_chance: float = 0.42
	match from_stage:
		"announcement":
			same_day_chance = 0.46
		"follow_up":
			same_day_chance = 0.5
		"reaction":
			same_day_chance = 0.55
		"twist":
			same_day_chance = 0.28
	var ticks_left: bool = last_tick < 300
	if randf() < same_day_chance and ticks_left:
		chain.due_day = calendar_day
		chain.prefer_premarket = false
		chain.due_tick = last_tick + randi_range(18, 70)
	else:
		chain.due_day = calendar_day + randi_range(1, 5)
		chain.prefer_premarket = randf() < 0.62
		chain.due_tick = 0 if chain.prefer_premarket else randi_range(20, 180)


func prune_to_universe(watchlist: Array[String], stocks: Array[Stock]) -> void:
	var keep: Array[EventChain] = []
	for chain in active:
		if not ARCS.has(chain.arc_id):
			continue
		if not _arc_allowed(ARCS[chain.arc_id], watchlist, stocks):
			continue
		keep.append(chain)
	active = keep


func _pick_available_arc(stocks: Array[Stock]) -> String:
	var taken: Array[String] = occupied_subjects()
	var watchlist: Array[String] = []
	for stock in stocks:
		watchlist.append(stock.symbol)
	var options: Array[String] = []
	for arc_id in ARCS.keys():
		var spec: Dictionary = ARCS[arc_id]
		var subject: String = str(spec["subject"])
		if taken.has(subject):
			continue
		if int(cooldowns.get(arc_id, -99)) > calendar_day:
			continue
		if not _arc_allowed(spec, watchlist, stocks):
			continue
		options.append(str(arc_id))
	if options.is_empty():
		return ""
	return options[randi() % options.size()]


func _arc_allowed(spec: Dictionary, watchlist: Array[String], stocks: Array[Stock]) -> bool:
	var scope: String = str(spec.get("scope", ""))
	if scope == "company":
		var subject: String = str(spec.get("subject", ""))
		if not watchlist.has(subject):
			return false
		for stock in stocks:
			if stock.symbol == subject:
				return stock.is_listed()
		return true
	if scope == "industry":
		return not news_generator.symbols_for_industry(stocks, str(spec.get("industry", ""))).is_empty()
	return true


static func arc_is_existential(arc_id: String) -> bool:
	if not ARCS.has(arc_id):
		return false
	var spec: Dictionary = ARCS[arc_id]
	var stages: Variant = spec.get("stages", {})
	if typeof(stages) != TYPE_DICTIONARY or not (stages as Dictionary).has("resolution"):
		return false
	var sides: Variant = (stages as Dictionary)["resolution"]
	if typeof(sides) != TYPE_DICTIONARY:
		return false
	var negatives: Variant = (sides as Dictionary).get("negative", [])
	if typeof(negatives) != TYPE_ARRAY:
		return false
	for item in negatives:
		if typeof(item) == TYPE_DICTIONARY and bool((item as Dictionary).get("existential", false)):
			return true
	return false


func _stage_item(arc_id: String, stage: String, positive: bool) -> Dictionary:
	var spec: Dictionary = ARCS[arc_id]
	var stages: Dictionary = spec["stages"]
	if not stages.has(stage):
		return {}
	var sides: Dictionary = stages[stage]
	var key: String = "positive" if positive else "negative"
	var items: Array = sides[key]
	var picked: Variant = items[randi() % items.size()]
	if typeof(picked) == TYPE_DICTIONARY:
		return picked
	return {}


func _symbols_for_chain(chain: EventChain, stocks: Array[Stock]) -> Array[String]:
	match chain.scope:
		"market":
			var all_names: Array[String] = []
			for stock in stocks:
				all_names.append(stock.symbol)
			return all_names
		"industry":
			return news_generator.symbols_for_industry(stocks, chain.industry)
		_:
			return [chain.subject]


func _start_cooldown(arc_id: String) -> void:
	cooldowns[arc_id] = calendar_day + randi_range(5, 12)


func _prune_cooldowns() -> void:
	var drop: Array[String] = []
	for arc_id in cooldowns.keys():
		if int(cooldowns[arc_id]) <= calendar_day:
			drop.append(str(arc_id))
	for arc_id in drop:
		cooldowns.erase(arc_id)
