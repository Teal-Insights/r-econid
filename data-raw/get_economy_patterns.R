economy_patterns <- tibble::tribble(
  ~economy_name, ~economy_regex, ~iso3c, ~iso2c,

  "Afghanistan", paste0(
    "afghan|", # base name
    "^AFG$|^AF$" # ISO codes
  ), "AFG", "AF",

  "Albania", paste0(
    "albania|",
    "^ALB$|^AL$"
  ), "ALB", "AL",

  "Algeria", paste0(
    "algeria|",
    "^DZA$|^DZ$"
  ), "DZA", "DZ",

  "American Samoa", paste0(
    "^(?=.*americ).*samoa|", # requires 'americ' before 'samoa'
    "^ASM$|^AS$"
  ), "ASM", "AS",

  "Andorra", paste0(
    "andorra|",
    "^AND$|^AD$"
  ), "AND", "AD",

  "Angola", paste0(
    "angola|",
    "^AGO$|^AO$"
  ), "AGO", "AO",

  "Anguilla", paste0(
    "anguill?a|", # handles both 'Anguilla' and 'Anguila' spellings
    "^AIA$|^AI$"
  ), "AIA", "AI",

  "Antarctica", paste0(
    "antarctica|",
    "^ATA$|^AQ$"
  ), "ATA", "AQ",

  "Antigua & Barbuda", paste0(
    "antigua|barbuda|",
    "^ATG$|^AG$"
  ), "ATG", "AG",

  "Argentina", paste0(
    "argentin|de la plata|", # matches argentina/argentine
    "^ARG$|^AR$"
  ), "ARG", "AR",

  "Armenia", paste0(
    "armenia|",
    "^ARM$|^AM$"
  ), "ARM", "AM",

  "Aruba", paste0(
    "^(?!.*bonaire).*\\baruba|", # exclude mentions with Bonaire
    "^ABW$|^AW$"
  ), "ABW", "AW",

  "Australia", paste0(
    "australia(?!.*new.?zealand)|", # negative lookahead to avoid matching "Australia New Zealand"
    "^AUS$|^AU$"
  ), "AUS", "AU",

  "Austria", paste0(
    "^(?!.*hungary).*austria|", # avoid matching "Austria-Hungary"
    "\\baustr.*\\bemp|", # historical: Austrian Empire
    "^AUT$|^AT$"
  ), "AUT", "AT",

  "Azerbaijan", paste0(
    "azerbaijan|",
    "^AZE$|^AZ$"
  ), "AZE", "AZ",

  "Bahamas", paste0(
    "bahamas|",
    "^BHS$|^BS$"
  ), "BHS", "BS",

  "Bahrain", paste0(
    "bahrain|",
    "^BHR$|^BH$"
  ), "BHR", "BH",

  "Bangladesh", paste0(
    "bangladesh|",
    "^(?=.*east).*paki?stan|", # historical: East Pakistan
    "^BGD$|^BD$"
  ), "BGD", "BD",

  "Barbados", paste0(
    "barbados|",
    "^BRB$|^BB$"
  ), "BRB", "BB",

  "Belarus", paste0(
    "belarus|",
    "belorus|",
    "byelo|", # historical: Byelorussia
    "^BLR$|^BY$"
  ), "BLR", "BY",

  "Belgium", paste0(
    "^(?!.*luxem).*belgium|", # avoid matching Luxembourg-Belgium
    "^BEL$|^BE$"
  ), "BEL", "BE",

  "Belize", paste0(
    "belize|",
    "^(?=.*british).*honduras|", # historical: British Honduras
    "^BLZ$|^BZ$"
  ), "BLZ", "BZ",

  "Benin", paste0(
    "benin|",
    "dahome|", # historical: Dahomey
    "^BEN$|^BJ$"
  ), "BEN", "BJ",

  "Bermuda", paste0(
    "bermuda|",
    "^BMU$|^BM$"
  ), "BMU", "BM",

  "Bhutan", paste0(
    "bhutan|",
    "druk|", # Name in Dzongkha language
    "^BTN$|^BT$"
  ), "BTN", "BT",

  "Bolivia", paste0(
    "bolivia|",
    "^BOL$|^BO$"
  ), "BOL", "BO",

  "Bosnia & Herzegovina", paste0(
    "herzegovina|",
    "bosnia|",
    "^BIH$|^BA$"
  ), "BIH", "BA",

  "Botswana", paste0(
    "botswana|",
    "bechuana|", # historical: Bechuanaland
    "^BWA$|^BW$"
  ), "BWA", "BW",

  "Bouvet Island", paste0(
    "bouvet|",
    "^BVT$|^BV$"
  ), "BVT", "BV",

  "Brazil", paste0(
    "brazil|",
    "^BRA$|^BR$"
  ), "BRA", "BR",

  "British Indian Ocean Territory", paste0(
    "british.?indian.?ocean|",
    "^IOT$|^IO$"
  ), "IOT", "IO",

  "British Virgin Islands", paste0(
    "^(?=.*\\bu\\.?\\s?k).*virgin|", # UK Virgin Islands
    "^(?=.*brit).*virgin|", # British Virgin Islands
    "^(?=.*kingdom).*virgin|", # United Kingdom Virgin Islands
    "^VGB$|^VG$"
  ), "VGB", "VG",

  "Brunei", paste0(
    "brunei|",
    "^BRN$|^BN$"
  ), "BRN", "BN",

  "Bulgaria", paste0(
    "bulgaria|",
    "^BGR$|^BG$"
  ), "BGR", "BG",

  "Burkina Faso", paste0(
    "burkina|",
    "\\bfaso|",
    "upper.?volta|", # historical: Upper Volta
    "^BFA$|^BF$"
  ), "BFA", "BF",

  "Burundi", paste0(
    "burundi|",
    "^BDI$|^BI$"
  ), "BDI", "BI",

  "Cambodia", paste0(
    "cambodia|",
    "kampuchea|", # historical
    "khmer|", # historical
    "^KHM$|^KH$"
  ), "KHM", "KH",

  "Cameroon", paste0(
    "cameroon|",
    "^CMR$|^CM$"
  ), "CMR", "CM",

  "Canada", paste0(
    "canada|",
    "^CAN$|^CA$"
  ), "CAN", "CA",

  "Cape Verde", paste0(
    "cabo.?verde|", # current official name
    "cape.?verde|", # historical English name
    "^CPV$|^CV$"
  ), "CPV", "CV",

  "Caribbean Netherlands", paste0(
    "^(?=.*bonaire).*eustatius|", # Bonaire, Sint Eustatius
    "^(?=.*carib).*netherlands|", # Caribbean Netherlands
    "\\bbes.?islands|", # BES Islands
    "^BES$|^BQ$"
  ), "BES", "BQ",

  "Cayman Islands", paste0(
    "cayman|",
    "^CYM$|^KY$"
  ), "CYM", "KY",

  "Central African Republic", paste0(
    "\\bcentral.african.(rep|emp)|",
    "ubangu?i-(c|s)hari|", # historical: Ubangi-Chari or Ou
    "^CAF$|^CF$"
  ), "CAF", "CF",

  "Chad", paste0(
    "\\bchad|", # word boundary to avoid matches like "attached"
    "^TCD$|^TD$"
  ), "TCD", "TD",

  "Chile", paste0(
    "\\bchile|", # word boundary to avoid matches like "archipelago"
    "^CHL$|^CL$"
  ), "CHL", "CL",

  "China", paste0(
    # exclude Macau, Hong Kong, Taiwan, Republic of China
    "^(?!.*\\bmac)(?!.*\\bhong)(?!.*\\btai)(?!rep).*china|",
    "prc|",
    "^CHN$|^CN$"
  ), "CHN", "CN",

  "Christmas Island", paste0(
    "christmas|",
    "^CXR$|^CX$"
  ), "CXR", "CX",


  "Cocos (Keeling) Islands", paste0(
    "\\bcocos|",
    "keeling|",
    "^CCK$|^CC$"
  ), "CCK", "CC",

  "Colombia", paste0(
    "colombia|",
    "^COL$|^CO$"
  ), "COL", "CO",

  "Comoros", paste0(
    "comoro|",
    "^COM$|^KM$"
  ), "COM", "KM",

  "Congo - Brazzaville", paste0(
    "^(?!.*\\bd.?m)(?!.*\\bd[\\.]?r)(?!.*kinshasa)(?!.*zaire)",
    "(?!.*belg)(?!.*l.opoldville)(?!.*free).*\\bcongo|", # exclude Democratic Republic of Congo references
    "^COG$|^CG$"
  ), "COG", "CG",

  "Congo - Kinshasa", paste0(
    "\\bd.?m.*congo|",
    "congo.*\\bd.?m|",
    "congo.*\\bd[\\.]?r|",
    "\\bd[\\.]?r.*congo|",
    "belgian.?congo|", # historical
    "congo.?free.?state|", # historical
    "kinshasa|",
    "zaire|", # historical
    "l.opoldville|", # historical
    "drc|droc|rdc|", # common abbreviations
    "^COD$|^CD$"
  ), "COD", "CD",

  "Cook Islands", paste0(
    "\\bcook|",
    "^COK$|^CK$"
  ), "COK", "CK",

  "Costa Rica", paste0(
    "costa.?rica|",
    "^CRI$|^CR$"
  ), "CRI", "CR",

  "Croatia", paste0(
    "croatia|",
    "^HRV$|^HR$"
  ), "HRV", "HR",

  "Cuba", paste0(
    "\\bcuba|", # word boundary to avoid matches like "incubator"
    "^CUB$|^CU$"
  ), "CUB", "CU",

  "Curaçao", paste0(
    "^(?!.*bonaire).*\\bcura(c|ç)ao|", # handles both c and ç, excludes Bonaire mentions
    "^CUW$|^CW$"
  ), "CUW", "CW",

  "Cyprus", paste0(
    "cyprus|cypriot|",
    "^CYP$|^CY$"
  ), "CYP", "CY",

  "Czechia", paste0(
    "^(?=.*rep).*czech|", # matches Czech Republic
    "czechia|", # newer official name
    "bohemia|", # historical
    "^CZE$|^CZ$"
  ), "CZE", "CZ",

  "Côte d'Ivoire", paste0(
    "ivoire|",
    "ivory|", # English name
    "^CIV$|^CI$"
  ), "CIV", "CI",

  "Denmark", paste0(
    "denmark|",
    "^DNK$|^DK$"
  ), "DNK", "DK",


  "Djibouti", paste0(
    "djibouti|",
    "the afars|",
    "somaliland|",
    "^DJI$|^DJ$"
  ), "DJI", "DJ",

  "Dominica", paste0(
    "dominica(?!n)|", # exclude Dominican Republic
    "^DMA$|^DM$"
  ), "DMA", "DM",

  "Dominican Republic", paste0(
    "dominican.rep|",
    "rep.*dominicana|",
    "^DOM$|^DO$"
  ), "DOM", "DO",

  "Ecuador", paste0(
    "ecuador|",
    "^ECU$|^EC$"
  ), "ECU", "EC",

  "Egypt", paste0(
    "egypt|",
    "^EGY$|^EG$"
  ), "EGY", "EG",

  "El Salvador", paste0(
    "el.?salvador|",
    "^SLV$|^SV$"
  ), "SLV", "SV",

  "Equatorial Guinea", paste0(
    "guine.*eq|",
    "eq.*guine|",
    "^(?=.*span).*guinea|", # historical: Spanish Guinea
    "^GNQ$|^GQ$"
  ), "GNQ", "GQ",

  "Eritrea", paste0(
    "eritrea|",
    "^ERI$|^ER$"
  ), "ERI", "ER",

  "Estonia", paste0(
    "estonia|",
    "eesti\\svabariik|",
    "^EST$|^EE$"
  ), "EST", "EE",

  "Eswatini", paste0(
    "eswatini|",
    "swaziland|", # historical name
    "^SWZ$|^SZ$"
  ), "SWZ", "SZ",

  "Ethiopia", paste0(
    "ethiopia|",
    "abyssinia|", # historical
    "^ETH$|^ET$"
  ), "ETH", "ET",

  "Falkland Islands", paste0(
    "falkland|",
    "malvinas|", # alternative name
    "^FLK$|^FK$"
  ), "FLK", "FK",

  "Faroe Islands", paste0(
    "f(a|ae|ø|æ)r(o|Ø)(e|y)|",
    "^FRO$|^FO$"
  ), "FRO", "FO",

  "Fiji", paste0(
    "fiji|",
    "^FJI$|^FJ$"
  ), "FJI", "FJ",

  "Finland", paste0(
    "finland|",
    "^FIN$|^FI$"
  ), "FIN", "FI",

  "France", paste0(
    "^(?!.*\\bdep)(?!.*martinique).*france|", # exclude French departments and territories
    "french.*(republic|state)|",
    "\\bgaul|", # historical
    "^FRA$|^FR$"
  ), "FRA", "FR",

  "French Guiana", paste0(
    "french.?gu(y|i)ana|", # handles spelling variations
    "^guyane$|",
    "^GUF$|^GF$"
  ), "GUF", "GF",

  "French Polynesia", paste0(
    "french.?polynesia|",
    "tahiti|", # commonly used name
    "^PYF$|^PF$"
  ), "PYF", "PF",

  "French Southern Territories", paste0(
    "french.?southern|",
    "^ATF$|^TF$"
  ), "ATF", "TF",

  "Gabon", paste0(
    "gabon|",
    "^GAB$|^GA$"
  ), "GAB", "GA",

  "Gambia", paste0(
    "gambia|",
    "^GMB$|^GM$"
  ), "GMB", "GM",

  "Georgia", paste0(
    "^(?!.*south).*georgia|", # exclude South Georgia
    "sakartvelo|",
    "^GEO$|^GE$"
  ), "GEO", "GE",

  "Germany", paste0(
    "^(?!.*east).*germany|", # exclude East Germany
    "^(?=.*\\bfed.*\\brep).*german|", # include Federal Republic of Germany
    "^DEU$|^DE$"
  ), "DEU", "DE",

  "Ghana", paste0(
    "ghana|",
    "gold.?coast|", # historical
    "^GHA$|^GH$"
  ), "GHA", "GH",

  "Gibraltar", paste0(
    "gibraltar|",
    "^GIB$|^GI$"
  ), "GIB", "GI",

  "Greece", paste0(
    "gree(ce|k)|",
    "hell(as|enic)|", # alternative names
    "^GRC$|^GR$"
  ), "GRC", "GR",

  "Greenland", paste0(
    "greenland|",
    "kalaallit|", # Greenlandic name
    "^GRL$|^GL$"
  ), "GRL", "GL",

  "Grenada", paste0(
    "grenada|",
    "^GRD$|^GD$"
  ), "GRD", "GD",

  "Guadeloupe", paste0(
    "guadeloupe|",
    "^GLP$|^GP$"
  ), "GLP", "GP",

  "Guam", paste0(
    "\\bguam|", # word boundary to avoid partial matches
    "^GUM$|^GU$"
  ), "GUM", "GU",


  "Guatemala", paste0(
    "guatemala|",
    "^GTM$|^GT$"
  ), "GTM", "GT",

  "Guernsey", paste0(
    "guernsey|",
    "^GGY$|^GG$"
  ), "GGY", "GG",

  "Guinea", paste0(
    "^(?!.*eq)(?!.*span)(?!.*bissau)(?!.*portu)(?!.*new).*guinea|", # exclude Equatorial Guinea, Guinea-Bissau, Papua New Guinea
    "^GIN$|^GN$"
  ), "GIN", "GN",

  "Guinea-Bissau", paste0(
    "bissau|",
    "^(?=.*portu).*guinea|", # historical: Portuguese Guinea
    "^GNB$|^GW$"
  ), "GNB", "GW",

  "Guyana", paste0(
    "^guyana|",
    "british.?gu(y|i)ana|", # historical
    "operative.*gu(y|i)ana|", # official name
    "^GUY$|^GY$"
  ), "GUY", "GY",

  "Haiti", paste0(
    "haiti|",
    "^HTI$|^HT$"
  ), "HTI", "HT",

  "Heard & McDonald Islands", paste0(
    "heard.*mcdonald|",
    "^HMD$|^HM$"
  ), "HMD", "HM",

  "Honduras", paste0(
    "^(?!.*brit).*honduras|", # exclude British Honduras (now Belize)
    "^HND$|^HN$"
  ), "HND", "HN",

  "Hong Kong SAR China", paste0(
    "hong.?kong|",
    "^HKG$|^HK$"
  ), "HKG", "HK",

  "Hungary", paste0(
    "^(?!.*austr).*hungary|", # exclude Austria-Hungary
    "^HUN$|^HU$"
  ), "HUN", "HU",

  "Iceland", paste0(
    "iceland|",
    "^ISL$|^IS$"
  ), "ISL", "IS",

  "India", paste0(
    "india(?!.*ocea)|", # exclude Indian Ocean Territory
    "hindustan|", # historical
    "bharat|", # Hindi name
    "^IND$|^IN$"
  ), "IND", "IN",

  "Indonesia", paste0(
    "indonesia|",
    "^IDN$|^ID$"
  ), "IDN", "ID",

  "Iran", paste0(
    "\\biran|",
    "persia|", # historical
    "^IRN$|^IR$"
  ), "IRN", "IR",

  "Iraq", paste0(
    "\\biraq|",
    "mesopotamia|", # historical
    "^IRQ$|^IQ$"
  ), "IRQ", "IQ",

  "Ireland", paste0(
    "^(?!.*north).*\\bireland|", # exclude Northern Ireland
    "Éire|", # Irish name
    "^IRL$|^IE$"
  ), "IRL", "IE",

  "Isle of Man", paste0(
    "^(?=.*isle).*\\bman|", # matches "Isle of Man" variations
    "^mann$|",
    "ellan vannin|", # Manx name
    "^IMN$|^IM$"
  ), "IMN", "IM",

  "Israel", paste0(
    "israel|",
    "^ISR$|^IL$"
  ), "ISR", "IL",

  "Italy", paste0(
    "italy|",
    "italian.?republic|",
    "^ITA$|^IT$"
  ), "ITA", "IT",

  "Jamaica", paste0(
    "jamaica|",
    "^JAM$|^JM$"
  ), "JAM", "JM",

  "Japan", paste0(
    "japan|",
    "^JPN$|^JP$"
  ), "JPN", "JP",

  "Jersey", paste0(
    "jersey|",
    "^JEY$|^JE$"
  ), "JEY", "JE",

  "Jordan", paste0(
    "jordan|",
    "^JOR$|^JO$"
  ), "JOR", "JO",

  "Kazakhstan", paste0(
    "kazak|",
    "^KAZ$|^KZ$"
  ), "KAZ", "KZ",

  "Kenya", paste0(
    "kenya|",
    "british.?east.?africa|", # historical
    "east.?africa.?prot|", # historical: East Africa Protectorate
    "^KEN$|^KE$"
  ), "KEN", "KE",

  "Kiribati", paste0(
    "kiribati|",
    "^KIR$|^KI$"
  ), "KIR", "KI",

  "Kuwait", paste0(
    "kuwait|",
    "^KWT$|^KW$"
  ), "KWT", "KW",

  "Kyrgyzstan", paste0(
    "kyrgyz|",
    "kirghiz|", # alternative spelling
    "^KGZ$|^KG$"
  ), "KGZ", "KG",

  "Laos", paste0(
    "\\blaos?\\b|", # matches Laos or Lao
    "^LAO$|^LA$"
  ), "LAO", "LA",

  "Latvia", paste0(
    "latvia|",
    "^LVA$|^LV$"
  ), "LVA", "LV",

  "Lebanon", paste0(
    "lebanon|",
    "^LBN$|^LB$"
  ), "LBN", "LB",

  "Lesotho", paste0(
    "lesotho|",
    "basuto|", # historical: Basutoland
    "^LSO$|^LS$"
  ), "LSO", "LS",

  "Liberia", paste0(
    "liberia|",
    "^LBR$|^LR$"
  ), "LBR", "LR",

  "Libya", paste0(
    "libya|",
    "^LBY$|^LY$"
  ), "LBY", "LY",

  "Liechtenstein", paste0(
    "liechtenstein|",
    "^LIE$|^LI$"
  ), "LIE", "LI",

  "Lithuania", paste0(
    "lithuania|",
    "^LTU$|^LT$"
  ), "LTU", "LT",

  "Luxembourg", paste0(
    "^(?!.*belg).*luxem|", # exclude Belgian Luxembourg
    "^LUX$|^LU$"
  ), "LUX", "LU",

  "Macao SAR China", paste0(
    "maca(o|u)|", # handles both spellings
    "^MAC$|^MO$"
  ), "MAC", "MO",

  "Madagascar", paste0(
    "madagascar|",
    "malagasy|", # alternative name
    "^MDG$|^MG$"
  ), "MDG", "MG",

  "Malawi", paste0(
    "malawi|",
    "nyasa|", # historical: Nyasaland
    "^MWI$|^MW$"
  ), "MWI", "MW",

  "Malaysia", paste0(
    "malaysia|",
    "^MYS$|^MY$"
  ), "MYS", "MY",

  "Maldives", paste0(
    "maldive|", # matches Maldives/Maldive
    "^MDV$|^MV$"
  ), "MDV", "MV",

  "Mali", paste0(
    "\\bmali\\b|", # word boundaries to avoid Somalia
    "^MLI$|^ML$"
  ), "MLI", "ML",

  "Malta", paste0(
    "\\bmalta|",
    "^MLT$|^MT$"
  ), "MLT", "MT",

  "Marshall Islands", paste0(
    "marshall|",
    "^MHL$|^MH$"
  ), "MHL", "MH",

  "Martinique", paste0(
    "martinique|",
    "^MTQ$|^MQ$"
  ), "MTQ", "MQ",

  "Mauritania", paste0(
    "mauritania|",
    "^MRT$|^MR$"
  ), "MRT", "MR",

  "Mauritius", paste0(
    "mauritius|",
    "^MUS$|^MU$"
  ), "MUS", "MU",

  "Mayotte", paste0(
    "\\bmayotte|",
    "^MYT$|^YT$"
  ), "MYT", "YT",

  "Mexico", paste0(
    "\\bmexic|", # matches Mexico/Mexican
    "^MEX$|^MX$"
  ), "MEX", "MX",

  "Micronesia", paste0(
    "micronesia|",
    "^FSM$|^FM$"
  ), "FSM", "FM",

  "Moldova", paste0(
    "moldov|",
    "b(a|e)ssarabia|", # historical: Bessarabia/Bassarabia
    "^MDA$|^MD$"
  ), "MDA", "MD",

  "Monaco", paste0(
    "monaco|",
    "^MCO$|^MC$"
  ), "MCO", "MC",

  "Mongolia", paste0(
    "mongolia|",
    "^MNG$|^MN$"
  ), "MNG", "MN",

  "Montenegro", paste0(
    "^(?!.*serbia).*montenegro|", # exclude Serbia and Montenegro
    "^MNE$|^ME$"
  ), "MNE", "ME",

  "Montserrat", paste0(
    "montserrat|",
    "^MSR$|^MS$"
  ), "MSR", "MS",

  "Morocco", paste0(
    "morocco|",
    "\\bmaroc|", # French version sometimes used
    "^MAR$|^MA$"
  ), "MAR", "MA",

  "Mozambique", paste0(
    "mozambique|",
    "^MOZ$|^MZ$"
  ), "MOZ", "MZ",

  "Myanmar", paste0(
    "myanmar|",
    "burma|", # historical
    "^MMR$|^MM$"
  ), "MMR", "MM",

  "Namibia", paste0(
    "namibia|",
    "^NAM$|^NA$"
  ), "NAM", "NA",

  "Nauru", paste0(
    "nauru|",
    "^NRU$|^NR$"
  ), "NRU", "NR",

  "Nepal", paste0(
    "nepal|",
    "^NPL$|^NP$"
  ), "NPL", "NP",

  "Netherlands", paste0(
    "^(?!.*\\bant)(?!.*\\bcarib).*netherlands|", # exclude Netherlands Antilles and Caribbean Netherlands
    "holland|", # common alternative name
    "^NLD$|^NL$"
  ), "NLD", "NL",

  "New Caledonia", paste0(
    "new.?caledonia|",
    "^NCL$|^NC$"
  ), "NCL", "NC",

  "New Zealand", paste0(
    "new.?zealand|",
    "^NZL$|^NZ$"
  ), "NZL", "NZ",

  "Nicaragua", paste0(
    "nicaragua|",
    "^NIC$|^NI$"
  ), "NIC", "NI",

  "Niger", paste0(
    "\\bniger(?!ia)|", # exclude Nigeria
    "^NER$|^NE$"
  ), "NER", "NE",

  "Nigeria", paste0(
    "nigeria|",
    "^NGA$|^NG$"
  ), "NGA", "NG",

  "Niue", paste0(
    "niue|",
    "^NIU$|^NU$"
  ), "NIU", "NU",

  "Norfolk Island", paste0(
    "norfolk|",
    "^NFK$|^NF$"
  ), "NFK", "NF",

  "North Korea", paste0(
    "korea.*people|",
    "dprk|d.p.r.k|",
    "korea.+(d.p.r|dpr|north|dem.*rep.*)|",
    "(d.p.r|dpr|north|dem.*rep.*).+korea|",
    "^PRK$|^KP$"
  ), "PRK", "KP",

  "North Macedonia", paste0(
    "macedonia|",
    "fyrom|", # former name
    "^MKD$|^MK$"
  ), "MKD", "MK",

  "Northern Mariana Islands", paste0(
    "mariana|",
    "^MNP$|^MP$"
  ), "MNP", "MP",

  "Norway", paste0(
    "norway|",
    "^NOR$|^NO$"
  ), "NOR", "NO",

  "Oman", paste0(
    "\\boman|", # word boundary to avoid 'woman' etc
    "trucial|", # historical
    "^OMN$|^OM$"
  ), "OMN", "OM",

  "Pakistan", paste0(
    "^(?!.*east).*paki?stan|", # exclude East Pakistan (now Bangladesh)
    "^PAK$|^PK$"
  ), "PAK", "PK",

  "Palau", paste0(
    "palau|",
    "^PLW$|^PW$"
  ), "PLW", "PW",

  "Palestinian Territories", paste0(
    "palestin|",
    "\\bgaza|",
    "west.?bank|",
    "^PSE$|^PS$"
  ), "PSE", "PS",

  "Panama", paste0(
    "panama|",
    "^PAN$|^PA$"
  ), "PAN", "PA",

  "Papua New Guinea", paste0(
    "papua|",
    "new.?guinea|",
    "^PNG$|^PG$"
  ), "PNG", "PG",

  "Paraguay", paste0(
    "paraguay|",
    "^PRY$|^PY$"
  ), "PRY", "PY",

  "Peru", paste0(
    "peru|",
    "^PER$|^PE$"
  ), "PER", "PE",

  "Philippines", paste0(
    "philippines|",
    "^PHL$|^PH$"
  ), "PHL", "PH",

  "Pitcairn Islands", paste0(
    "pitcairn|",
    "^PCN$|^PN$"
  ), "PCN", "PN",

  "Poland", paste0(
    "poland|",
    "^POL$|^PL$"
  ), "POL", "PL",

  "Portugal", paste0(
    "portugal|",
    "^PRT$|^PT$"
  ), "PRT", "PT",

  "Puerto Rico", paste0(
    "puerto.?rico|",
    "^PRI$|^PR$"
  ), "PRI", "PR",

  "Qatar", paste0(
    "qatar|",
    "^QAT$|^QA$"
  ), "QAT", "QA",

  "Romania", paste0(
    "r(o|u|ou)mania|", # handle spelling variations
    "^ROU$|^RO$"
  ), "ROU", "RO",

  "Russia", paste0(
    "\\brussia|",
    "soviet.?union|",
    "u\\.?s\\.?s\\.?r|",
    "socialist.?republics|",
    "^RUS$|^RU$"
  ), "RUS", "RU",

  "Rwanda", paste0(
    "rwanda|",
    "^RWA$|^RW$"
  ), "RWA", "RW",

  "Réunion", paste0(
    "r(e|é)union|", # handles both e and é spellings
    "^REU$|^RE$"
  ), "REU", "RE",

  "Saint Martin (French part)", paste0(
    "saint.martin.*FR|",
    "^(?=.*collectivity).*martin|",
    "^(?=.*france).*martin(?!ique)|", # exclude Martinique
    "^(?=.*french).*martin(?!ique)|", # exclude Martinique
    "^MAF$|^MF$"
  ), "MAF", "MF",

  "Samoa", paste0(
    "^(?!.*amer).*samoa|", # exclude American Samoa
    "^WSM$|^WS$"
  ), "WSM", "WS",

  "San Marino", paste0(
    "san.?marino|",
    "^SMR$|^SM$"
  ), "SMR", "SM",

  "Saudi Arabia", paste0(
    "\\bsa\\w*.?arabia|",
    "^SAU$|^SA$"
  ), "SAU", "SA",

  "Senegal", paste0(
    "senegal|",
    "^SEN$|^SN$"
  ), "SEN", "SN",

  "Serbia", paste0(
    "^(?!.*monte).*serbia|", # exclude Montenegro
    "^SRB$|^RS$"
  ), "SRB", "RS",

  "Seychelles", paste0(
    "seychell|",
    "^SYC$|^SC$"
  ), "SYC", "SC",

  "Sierra Leone", paste0(
    "sierra|",
    "^SLE$|^SL$"
  ), "SLE", "SL",

  "Singapore", paste0(
    "singapore|",
    "^SGP$|^SG$"
  ), "SGP", "SG",

  "Sint Maarten", paste0(
    "^(?!.*martin)(?!.*saba).*maarten|", # exclude Saint Martin and Saba
    "^SXM$|^SX$"
  ), "SXM", "SX",

  "Slovakia", paste0(
    "^(?!.*cze).*slovak|", # exclude Czechoslovakia
    "^SVK$|^SK$"
  ), "SVK", "SK",

  "Slovenia", paste0(
    "slovenia|",
    "^SVN$|^SI$"
  ), "SVN", "SI",

  "Solomon Islands", paste0(
    "solomon|",
    "^SLB$|^SB$"
  ), "SLB", "SB",

  "Somalia", paste0(
    "somalia|",
    "^SOM$|^SO$"
  ), "SOM", "SO",

  "South Africa", paste0(
    "south.africa|",
    "s\\.?africa|",
    "^ZAF$|^ZA$"
  ), "ZAF", "ZA",

  "South Georgia & South Sandwich Islands", paste0(
    "south.?georgia|",
    "sandwich|",
    "^SGS$|^GS$"
  ), "SGS", "GS",

  "South Korea", paste0(
    "^(?!.*d.*p.*r)(?!.*democrat)(?!.*dem.*rep)(?!.*people)(?!.*north).*\\bkorea",
    "(?!.*d.*p.*r)(?!.*dem.*rep)|", # complex negative lookaheads to exclude North Korea
    "^KOR$|^KR$"
  ), "KOR", "KR",

  "South Sudan", paste0(
    "\\bs\\w*.?sudan|",
    "^SSD$|^SS$"
  ), "SSD", "SS",

  "Spain", paste0(
    "spain|",
    "^ESP$|^ES$"
  ), "ESP", "ES",

  "Sri Lanka", paste0(
    "sri.?lanka|",
    "ceylon|", # historical
    "^LKA$|^LK$"
  ), "LKA", "LK",

  "St. Barthélemy", paste0(
    "barth(e|é)lemy|", # handle both spellings
    "^BLM$|^BL$"
  ), "BLM", "BL",

  "St. Helena", paste0(
    "helena|",
    "^SHN$|^SH$"
  ), "SHN", "SH",

  "St. Kitts & Nevis", paste0(
    "kitts|",
    "\\bnevis|",
    "^KNA$|^KN$"
  ), "KNA", "KN",

  "St. Lucia", paste0(
    "\\blucia|",
    "^LCA$|^LC$"
  ), "LCA", "LC",

  "St. Pierre & Miquelon", paste0(
    "miquelon|",
    "^SPM$|^PM$"
  ), "SPM", "PM",

  "St. Vincent & Grenadines", paste0(
    "vincent|",
    "^VCT$|^VC$"
  ), "VCT", "VC",

  "Sudan", paste0(
    "^(?!.*\\bs(?!u)).*sudan|", # exclude South Sudan
    "^SDN$|^SD$"
  ), "SDN", "SD",

  "Suriname", paste0(
    "surinam|",
    "dutch.?gu(y|i)ana|", # historical
    "^SUR$|^SR$"
  ), "SUR", "SR",

  "Svalbard & Jan Mayen", paste0(
    "svalbard|",
    "jan.?mayen|",
    "^SJM$|^SJ$"
  ), "SJM", "SJ",

  "Sweden", paste0(
    "sweden|",
    "^SWE$|^SE$"
  ), "SWE", "SE",

  "Switzerland", paste0(
    "switz|",
    "swiss|",
    "^CHE$|^CH$"
  ), "CHE", "CH",

  "Syria", paste0(
    "syria|",
    "^SYR$|^SY$"
  ), "SYR", "SY",

  "São Tomé & Príncipe", paste0(
    "\\bs(a|ã)o.?tom(e|é)|", # handles different spellings
    "^STP$|^ST$"
  ), "STP", "ST",

  "Taiwan", paste0(
    "taiwan|",
    "taipei|",
    "formosa|", # historical
    "^(?!.*peo)(?=.*rep).*china|", # Republic of China but not People's Republic
    "^TWN$|^TW$"
  ), "TWN", "TW",

  "Tajikistan", paste0(
    "tajik|",
    "^TJK$|^TJ$"
  ), "TJK", "TJ",

  "Tanzania", paste0(
    "tanzania|",
    "^TZA$|^TZ$"
  ), "TZA", "TZ",

  "Thailand", paste0(
    "thailand|",
    "\\bsiam|", # historical
    "^THA$|^TH$"
  ), "THA", "TH",

  "Timor-Leste", paste0(
    "^(?=.*leste).*timor|",
    "^(?=.*east).*timor|",
    "^TLS$|^TL$"
  ), "TLS", "TL",

  "Togo", paste0(
    "togo|",
    "^TGO$|^TG$"
  ), "TGO", "TG",

  "Tokelau", paste0(
    "tokelau|",
    "^TKL$|^TK$"
  ), "TKL", "TK",

  "Tonga", paste0(
    "tonga|",
    "^TON$|^TO$"
  ), "TON", "TO",

  "Trinidad & Tobago", paste0(
    "trinidad|",
    "tobago|",
    "^TTO$|^TT$"
  ), "TTO", "TT",

  "Tunisia", paste0(
    "tunisia|",
    "^TUN$|^TN$"
  ), "TUN", "TN",

  "Türkiye", paste0(
    "t(ü|u)rkiye|",
    "turkey(?!.*cyprus)|", # exclude Northern Cyprus
    "^TUR$|^TR$"
  ), "TUR", "TR",

  "Turkmenistan", paste0(
    "turkmen|",
    "^TKM$|^TM$"
  ), "TKM", "TM",

  "Turks & Caicos Islands", paste0(
    "turks|",
    "caicos|",
    "^TCA$|^TC$"
  ), "TCA", "TC",

  "Tuvalu", paste0(
    "tuvalu|",
    "^TUV$|^TV$"
  ), "TUV", "TV",

  "U.S. Virgin Islands", paste0(
    "^(?=.*\\bu\\.?\\s?s).*virgin|",
    "^(?=.*states).*virgin|", # US Virgin Islands variations
    "^VIR$|^VI$"
  ), "VIR", "VI",

  "Uganda", paste0(
    "uganda|",
    "^UGA$|^UG$"
  ), "UGA", "UG",

  "Ukraine", paste0(
    "ukrain|",
    "^UKR$|^UA$"
  ), "UKR", "UA",

  "United Arab Emirates", paste0(
    "emirates|",
    "^u\\.?a\\.?e\\.?$|",
    "united.?arab.?em|",
    "^ARE$|^AE$"
  ), "ARE", "AE",

  "United Kingdom", paste0(
    "united.?kingdom|",
    "britain|",
    "^u\\.?k\\.?$|",
    "^GBR$|^GB$"
  ), "GBR", "GB",

  "United States", paste0(
    "united.?states\\b(?!.*islands)|", # exclude US islands
    "\\bu\\.?s\\.?a\\.?\\b|",
    "^\\s*u\\.?s\\.?\\b(?!.*islands)|",
    "^USA$|^US$"
  ), "USA", "US",

  "United States Minor Outlying Islands", paste0(
    "minor.?outlying.?is|",
    "^UMI$|^UM$"
  ), "UMI", "UM",

  "Uruguay", paste0(
    "uruguay|",
    "^URY$|^UY$"
  ), "URY", "UY",

  "Uzbekistan", paste0(
    "uzbek|",
    "^UZB$|^UZ$"
  ), "UZB", "UZ",

  "Vanuatu", paste0(
    "vanuatu|",
    "new.?hebrides|", # historical
    "^VUT$|^VU$"
  ), "VUT", "VU",

  "Vatican City", paste0(
    "holy.?see|",
    "vatican|",
    "papal.?st|", # variations including Papal State
    "^VAT$|^VA$"
  ), "VAT", "VA",

  "Venezuela", paste0(
    "venezuela|",
    "^VEN$|^VE$"
  ), "VEN", "VE",

  "Vietnam", paste0(
    "^(?!south)(?!republic).*viet.?nam(?!.*south)|",
    "democratic.republic.of.vietnam|",
    "socialist.republic.of.viet.?nam|",
    "north.viet.?nam|",
    "viet.?nam.north|",
    "^VNM$|^VN$"
  ), "VNM", "VN",

  "Wallis & Futuna", paste0(
    "futuna|",
    "wallis|",
    "^WLF$|^WF$"
  ), "WLF", "WF",

  "Western Sahara", paste0(
    "western.sahara|",
    "^ESH$|^EH$"
  ), "ESH", "EH",

  "Yemen", paste0(
    "^(?!.*arab)(?!.*north)(?!.*sana)(?!.*peo)(?!.*dem)(?!.*south)",
    "(?!.*aden)(?!.*\\bp\\.?d\\.?r).*yemen|", # exclude historical divisions
    "^YEM$|^YE$"
  ), "YEM", "YE",

  "Zambia", paste0(
    "zambia|",
    "northern.?rhodesia|", # historical
    "^ZMB$|^ZM$"
  ), "ZMB", "ZM",

  "Zimbabwe", paste0(
    "zimbabwe|",
    "^(?!.*northern).*rhodesia|", # historical, exclude Northern Rhodesia (Zambia)
    "^ZWE$|^ZW$"
  ), "ZWE", "ZW",

  "Åland Islands", paste0(
    "^[å|a]land|", # handles both å and a spelling
    "^ALA$|^AX$"
  ), "ALA", "AX"
)

# Save data --------------------------------------------------------------

usethis::use_data(
  economy_patterns,
  overwrite = TRUE, internal = FALSE
)
