local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node
local rep = require("luasnip.extras").rep

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
        i(1, "value"),
        t(" = String::new();"),
        t({ "", "" }),
        t("io::stdin().read_line(&mut "),
        rep(1),
        t(").unwrap();"),
        t({ "", "" }),
        t("let "),
        rep(1),
        t(": "),
        i(2, "i32"),
        t(" = "),
        rep(1),
        t(".trim().parse().unwrap();"),
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

    s("cps", {
        t("let "),
        i(1, "var"),
        t(": "),
        i(2, "Vec"),
        t("<"),
        i(3, "i32"),
        t("> = "),
        i(4, "input"),
        t({ "", "\t" }),
        t(".trim()"),
        t({ "", "\t" }),
        t(".split("),
        i(5, "\",\""),
        t(")"),
        t({ "", "\t" }),
        t(".map(|s| s.trim().parse::<"),
        rep(3),
        t(">().unwrap())"),
        t({ "", "\t" }),
        t(".collect();"),
        i(0),
    }),

    s("fori", {
        t("for "),
        i(1, "i"),
        t(" in 0.."),
        i(2, "res"),
        t(".len() {"),
        t({ "", "\t" }),
        d(3, function(args)
            local var = args[1][1]
            local iter = args[2][1]
            return sn(nil, {
                i(1, 'println!("{}", ' .. iter .. '[' .. var .. ']);'),
            })
        end, { 1, 2 }),
        t({ "", "" }),
        t("}"),
        i(0),
    }),
}
