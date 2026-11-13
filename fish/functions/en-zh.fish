function en-zh --description "Look up Chinese translation of common English words (top 100)"
    # Flag handlers
    switch "$argv[1]"
        case --list -l
            echo "Available words (100):"
            echo ""
            echo "── Pronouns: I, you, he, she, it, we, they, me, him, them, us"
            echo "── Possessives: my, your, his, her, its, our, their"
            echo "── Demonstratives: this, that, these, those, all, some, any, no, other, many, most"
            echo "── Auxiliaries: be, am, is, are, was, were, been, have, has, had, do, does, did"
            echo "── Modals: will, would, can, could, should, may"
            echo "── Action verbs: say, make, go, know, take, see, come, think, look, use, find, give, tell, work, call"
            echo "── Conjunctions: and, but, or, as, if, because, than, so"
            echo "── Prepositions: in, on, at, to, from, into, over, out, of, for, with, about, by, like, through, after"
            echo "── Articles: the, a, an"
            echo "── Adverbs: not, up, down, then, now, only, just, when, how, also, very, even, back, well"
            echo "── Nouns: time, year, people, way, day, man, thing, child, children"
            echo "── Adjectives: good, new, first, last, long, great, little"
            return 0

        case --search -s
            if test (count $argv) -lt 2
                echo "Usage: en-zh --search <pattern>"
                return 1
            end
            set -l pattern $argv[2]
            set -l dict i=我 you="你 / 您" he=他 she=她 it=它 we=我们 they=他们 me="我 (宾格)" him="他 (宾格)" them="他们 (宾格)" us="我们 (宾格)" my=我的 your="你的 / 您的" his=他的 her=她的 its=它的 our=我们的 their=他们的 this=这个 that=那个 these=这些 those=那些 all="所有 / 全部" some=一些 any=任何 no="没有 / 不" other=其他的 many=许多 most=大多数 be="是 (存在)" am=是 is=是 are=是 was="是 (过去式)" were="是 (过去式)" been="是 (过去分词)" have="有 / 已经" has="有 / 已经" had="有 / 已经" do="做 / 助动词" does="做 / 助动词" did="做 / 助动词" will=将会 would="会 / 过去愿意" can="能 / 可以" could="能够 (过去式)" should=应该 may="也许 / 可以" say=说 make="制作 / 使得" go=去 know=知道 take="拿 / 取 / 花费" see=看见 come=来 think="想 / 认为" look="看 / 显得" use=使用 find=找到 give=给 tell=告诉 work=工作 call="呼叫 / 打电话" and="和 / 而且" but=但是 or=或者 as="作为 / 当...时 / 因为" if=如果 because=因为 than=比 so="所以 / 如此" in="在...里面" on="在...上面" at="在 (某处/某时)" to="到 / 向" from="来自 / 从" into=进入 over="在...上方 / 越过" out="出去 / 在外" of="...的" for="为了 / 给" with="跟着 / 带有 / 用" about="关于 / 大约" by="被 / 通过 / 在...旁" like="像 / 如同" through="穿过 / 通过" after="在...之后" the="这 / 那 (定冠词)" a="一个 (不定冠词)" an="一个 (元音前)" not="不 (否定)" up=向上 down=向下 then="那么 / 然后" now=现在 only="只有 / 仅仅" just="刚刚 / 仅仅" when="什么时候 / 当...时" how="如何 / 怎样" also="也 / 并且" very=非常 even=甚至 back="背后 / 返回" well="很好地" time=时间 year=年 people="人 / 人们" way="方法 / 道路" day="白天 / 一天" man="男人 / 人类" thing="事情 / 物品" child=儿童 children=孩子们 good=好的 new=新的 first="第一 / 首先" last="最后的 / 过去" long=长的 great="伟大的 / 棒的" little="小的 / 很少"
            set -l found 0
            for entry in $dict
                set -l k (string split -m1 "=" -- $entry)[1]
                if string match -qi -- "*$pattern*" "$k"
                    set -l v (string split -m1 "=" -- $entry)[2..-1] | string join "="
                    echo "$k → $v"
                    set found 1
                end
            end
            if test $found -eq 0
                echo "No words match '$pattern'"
            end
            return 0

        case --help -h
            echo "Usage: en-zh <word> ..."
            echo "       en-zh --list          List all available words"
            echo "       en-zh --search <pat>  Search words matching pattern"
            echo "       en-zh --help          Show this help"
            echo ""
            echo "Look up Chinese translation of common English words."
            return 0
    end

    if test (count $argv) -eq 0
        echo "Usage: en-zh <word>"
        echo "Try en-zh --help for more info"
        return 1
    end

    for word in $argv
        set -l w (string lower -- $word)

        # ── 1. Pronouns & Determiners ──
        # Core Pronouns
        switch "$w"
            case i
                echo "我"
                continue
            case you
                echo "你 / 您"
                continue
            case he
                echo "他"
                continue
            case she
                echo "她"
                continue
            case it
                echo "它"
                continue
            case we
                echo "我们"
                continue
            case they
                echo "他们"
                continue
            case me
                echo "我 (宾格)"
                continue
            case him
                echo "他 (宾格)"
                continue
            case them
                echo "他们 (宾格)"
                continue
            case us
                echo "我们 (宾格)"
                continue
            # Possessives
            case my
                echo "我的"
                continue
            case your
                echo "你的 / 您的"
                continue
            case his
                echo "他的"
                continue
            case her
                echo "她的"
                continue
            case its
                echo "它的"
                continue
            case our
                echo "我们的"
                continue
            case their
                echo "他们的"
                continue
            # Demonstratives & Quantifiers
            case this
                echo "这个"
                continue
            case that
                echo "那个"
                continue
            case these
                echo "这些"
                continue
            case those
                echo "那些"
                continue
            case all
                echo "所有 / 全部"
                continue
            case some
                echo "一些"
                continue
            case any
                echo "任何"
                continue
            case no
                echo "没有 / 不"
                continue
            case other
                echo "其他的"
                continue
            case many
                echo "许多"
                continue
            case most
                echo "大多数"
                continue

            # ── 2. Verbs & Auxiliaries ──
            # Stative & Auxiliary
            case be
                echo "是 (存在)"
                continue
            case am
                echo "是"
                continue
            case is
                echo "是"
                continue
            case are
                echo "是"
                continue
            case was
                echo "是 (过去式)"
                continue
            case were
                echo "是 (过去式)"
                continue
            case been
                echo "是 (过去分词)"
                continue
            case have has had
                echo "有 / 已经"
                continue
            case do does did
                echo "做 / 助动词"
                continue
            case will
                echo "将会"
                continue
            case would
                echo "会 / 过去愿意"
                continue
            case can
                echo "能 / 可以"
                continue
            case could
                echo "能够 (过去式)"
                continue
            case should
                echo "应该"
                continue
            case may
                echo "也许 / 可以"
                continue
            # Action verbs
            case say
                echo "说"
                continue
            case make
                echo "制作 / 使得"
                continue
            case go
                echo "去"
                continue
            case know
                echo "知道"
                continue
            case take
                echo "拿 / 取 / 花费"
                continue
            case see
                echo "看见"
                continue
            case come
                echo "来"
                continue
            case think
                echo "想 / 认为"
                continue
            case look
                echo "看 / 显得"
                continue
            case use
                echo "使用"
                continue
            case find
                echo "找到"
                continue
            case give
                echo "给"
                continue
            case tell
                echo "告诉"
                continue
            case work
                echo "工作"
                continue
            case call
                echo "呼叫 / 打电话"
                continue

            # ── 3. Connectors & Prepositions ──
            # Conjunctions
            case and
                echo "和 / 而且"
                continue
            case but
                echo "但是"
                continue
            case or
                echo "或者"
                continue
            case as
                echo "作为 / 当...时 / 因为"
                continue
            case if
                echo "如果"
                continue
            case because
                echo "因为"
                continue
            case than
                echo "比"
                continue
            case so
                echo "所以 / 如此"
                continue
            # Prepositions
            case in
                echo "在...里面"
                continue
            case on
                echo "在...上面"
                continue
            case at
                echo "在 (某处/某时)"
                continue
            case to
                echo "到 / 向"
                continue
            case from
                echo "来自 / 从"
                continue
            case into
                echo "进入"
                continue
            case over
                echo "在...上方 / 越过"
                continue
            case out
                echo "出去 / 在外"
                continue
            case of
                echo "...的"
                continue
            case for
                echo "为了 / 给"
                continue
            case with
                echo "跟着 / 带有 / 用"
                continue
            case about
                echo "关于 / 大约"
                continue
            case by
                echo "被 / 通过 / 在...旁"
                continue
            case like
                echo "像 / 如同"
                continue
            case through
                echo "穿过 / 通过"
                continue
            case after
                echo "在...之后"
                continue

            # ── 4. Articles & Adverbs ──
            case the
                echo "这 / 那 (定冠词)"
                continue
            case a
                echo "一个 (不定冠词)"
                continue
            case an
                echo "一个 (元音前)"
                continue
            case not
                echo "不 (否定)"
                continue
            case up
                echo "向上"
                continue
            case down
                echo "向下"
                continue
            case then
                echo "那么 / 然后"
                continue
            case now
                echo "现在"
                continue
            case only
                echo "只有 / 仅仅"
                continue
            case just
                echo "刚刚 / 仅仅"
                continue
            case when
                echo "什么时候 / 当...时"
                continue
            case how
                echo "如何 / 怎样"
                continue
            case also
                echo "也 / 并且"
                continue
            case very
                echo "非常"
                continue
            case even
                echo "甚至"
                continue
            case back
                echo "背后 / 返回"
                continue
            case well
                echo "很好地"
                continue

            # ── 5. Core Nouns & Adjectives ──
            case time
                echo "时间"
                continue
            case year
                echo "年"
                continue
            case people
                echo "人 / 人们"
                continue
            case way
                echo "方法 / 道路"
                continue
            case day
                echo "白天 / 一天"
                continue
            case man
                echo "男人 / 人类"
                continue
            case thing
                echo "事情 / 物品"
                continue
            case child
                echo "儿童"
                continue
            case children
                echo "孩子们"
                continue
            case good
                echo "好的"
                continue
            case new
                echo "新的"
                continue
            case first
                echo "第一 / 首先"
                continue
            case last
                echo "最后的 / 过去"
                continue
            case long
                echo "长的"
                continue
            case great
                echo "伟大的 / 棒的"
                continue
            case little
                echo "小的 / 很少"
                continue
        end

        # If we got here, word was not found
        echo "Not found: $w"
    end
end
