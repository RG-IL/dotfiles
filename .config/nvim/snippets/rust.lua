local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node

return {

    s("fn", {
        t("fn "),
        i(1, "name"),
        t("("),
        i(2),
        t(")"),
        c(3, {
            t(""),
            t(" -> ()"),
        }),
        t({ " {", "\t" }),
        i(4),
        t({ "}", "" }),
        i(0),
    }),

    s("pfn", {
        t("pub fn "),
        i(1, "name"),
        t("("),
        i(2),
        t(")"),
        c(3, {
            t(""),
            t(" -> ()"),
        }),
        t({ " {", "\t" }),
        i(4),
        t({ "}", "" }),
        i(0),
    }),

    s("st", {
        c(1, {
            t(""),
            t("pub "),
        }),
        t("struct "),
        i(2, "Name"),
        c(3, {
            t(""),
            t("()"),
        }),
        i(0),
    }),

    s("en", {
        c(1, {
            t(""),
            t("pub "),
        }),
        t("enum "),
        i(2, "Name"),
        t({ " {", "\t" }),
        i(3),
        t({ "}", "" }),
        i(0),
    }),

    s("imp", {
        t("impl "),
        i(1, "Type"),
        t({ " {", "\t" }),
        i(2),
        t({ "}", "" }),
        i(0),
    }),

    s("m", {
        t("match "),
        i(1),
        t({ " {", "\t" }),
        i(2, "_ => ()"),
        t({ "}", "" }),
        i(0),
    }),

    s("fo", {
        t("for "),
        i(1, "item"),
        t(" in "),
        i(2),
        t({ " {", "\t" }),
        i(3),
        t({ "}", "" }),
        i(0),
    }),

    s("ifl", {
        t("if let "),
        i(1, "Some(x)"),
        t(" = "),
        i(2),
        t({ " {", "\t" }),
        i(3),
        t({ "}", "" }),
        i(0),
    }),

    s("v", {
        t("vec!["),
        i(1),
        t("]"),
        i(0),
    }),

    s("der", {
        t("#[derive("),
        i(1, "Debug, Clone"),
        t(")]"),
        i(0),
    }),

    s("pr", {
        t('println!("'),
        i(1),
        t('");'),
        i(0),
    }),

    s("un", {
        i(1, "opt"),
        c(2, {
            t(".unwrap();"),
            t(".unwrap_or("),
            i(1, "default"),
            t(");"),
            t(".expect(\""),
            i(1, "msg"),
            t("\");"),
        }),
        i(0),
    }),

    s("oc", {
        t("Some("),
        i(1),
        t(")"),
        i(0),
    }),

    s("on", {
        t("None"),
        i(0),
    }),

    s("ro", {
        t("Ok("),
        i(1),
        t(")"),
        i(0),
    }),

    s("re", {
        t("Err("),
        i(1),
        t(")"),
        i(0),
    }),

    s("tl", {
        t("todo!(\""),
        i(1),
        t("\")"),
        i(0),
    }),

    s("sm", {
        t("String::from("),
        i(1),
        t(")"),
        i(0),
    }),

    s("bx", {
        t("Box::new("),
        i(1),
        t(")"),
        i(0),
    }),

    s("in", {
        t("let mut "),
        i(1, "input"),
        t(" = String::new();"),
        t({ "", "" }),
        t("io::stdin().read_line(&mut "),
        f(function(args) return args[1][1] end, { 1 }),
        t(").unwrap();"),
        i(0),
    }),

    s("inc", {
        t("let mut input = String::new();"),
        t({ "", "" }),
        t("io::stdin().read_line(&mut input).unwrap();"),
        t({ "", "" }),
        t("let "),
        i(1, "num"),
        t(": "),
        i(2, "i32"),
        t(" = input.trim().parse().unwrap();"),
        i(0),
    }),

    s("test", {
        t({ "#[test]", "fn " }),
        i(1, "test_name"),
        t({ "() {", "\t" }),
        i(2),
        t({ "}", "" }),
        i(0),
    }),
}
