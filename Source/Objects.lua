AuctionatorTools = {
	mainFrame = nil,
	Tabs = {
		Shopping = {},
		Selling = {},
		Options = {
			default = {}
		}
	}

}

ATDB_Defaults = {
	global = {
		quantity = {

		},
		Config = {
			Debug = false
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
