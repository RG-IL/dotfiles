local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

return {

    s("pro", {
        c(1, {
            t("public "),
            t("private "),
            t("protected "),
            t("internal "),
        }),
        i(2, "int MyProperty"),
        t(" { "),
        c(3, {
            t("get; set;"),
            t("get; private set;"),
            t("private get; set;"),
        }),
        t(" }"),
        i(0),
    }),

    s("ni", {
        i(1, "Type"),
        t(" "),
        i(2, "instanceName"),
        t(" = new "),
        f(function(args)
            return args[1][1]
        end, { 1 }),
        t("("),
        i(3),
        t(");"),
        i(0),
    }),
}
