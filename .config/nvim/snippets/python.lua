local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    s("fori", {
        t("for i in range("),
        i(1, "10"),
        t({ "):", "    " }),
        i(2, "print(i)"),
    }),

    s("fn", {
        t("def "),
        i(1, "name"),
        t("("),
        i(2, "args"),
        t({ "):", "    " }),
        i(3, "pass"),
    }),
}
