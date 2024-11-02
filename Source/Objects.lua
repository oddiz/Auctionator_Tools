AuctionatorTools = {
	Debug = {},
	mainFrame = nil,
	Tabs = {
		Shopping = {},
		Selling = {},
		Options = {
			default = {}
		}
	},
	Config = {
		Debug = true
	}
}

ATDB_Defaults = {
	global = {
		quantity = {

		}
	},
	profile = {
		Shopping = {
			meanQty = 400
		},
		Selling = {
			SkipLogic = {
				masterSwitch = false,
				processUndercut = false,
				restockEnabled = false,
				restockThreshold = 0.5,
				preference = "SKIP", -- "SKIP" or "REFRESH"
			},
			ImprovedQuantity = {
				useCustomQty = true
			}
		}
	}
}
