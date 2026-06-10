local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {

    s("inc", {
        t("#include <"),
        i(1, "stdio.h"),
        t(">"),
        i(0),
    }),

    s("p", {
        t("printf(\""),
        i(1),
        t("\\n\");"),
        i(0),
    }),

    s("pr", {
        t("printf(\""),
        i(1),
        t("\\n\");"),
        i(0),
    }),
}
