#### Bibliography parser

# import fileinput
# from pprint import pprint

export Parser
export clear_comments

using JSON

"""Main struct for Bibtex parsing"""
struct Parser
    data
    token
    token_type
    _next_token
    hashtable
    mode
    records
    line
    white
    nl
    token_re
end

"""Return the bibtex content without comments"""
function clear_comments(data)
    res = replace(data, r"(%.*\n)" => "")
    res = replace(res, r"(comment [^\n]*\n)" => "")
    return res
end

"""Returns a token iterator"""
function tokenize(self)
    for item in self.token_re.finditer(self.data)
        i = item.group(0)
        if self.white.match(i)
            if self.nl.match(i)
                self.line += 1
            end
            continue
        else
            yield i
        end
    end
end

"""Parses self.data and stores the parsed bibtex to self.rec"""
function parse(self)
    while true
        try
            self.next_token()
            while self.database()
            end
        catch
            error("StopIteration")
        end
    end
end

"""Outer constructor"""
function Parser(self, data)
    token = nothing
    token_type = nothing
    token_re = r"([^\s\"#%'(){}@,=]+|\n|@|\"|{|}|=|,)"
    _next_token = self.tokenize().next
    hashtable = Dict()
    mode = nothing
    records = Dict()
    line = 1

    # compile some regexes
    white = r"[\n|\s]+"
    nl = r"[\n]"
    return Parser(data,
        token,
        token_type,
        _next_token,
        hashtable,
        mode,
        records,
        line,
        white,
        nl,
        token_re)
end

"""Returns next token"""
function next_token(self)
    self.token = self._next_token()
    #print self.line, self.token
end

"""Database"""
function database(self)
    if self.token == "@"
        self.next_token()
        self.entry()
    end
end

"""Entry"""
function entry(self)
    if lowercase(self.token) == "string"
        self.mode = "string"
        self.string()
    else
        self.mode = "record"
        self.record()
    end
    self.mode = nothing
end

"""String"""
function string(self)
    if lowercase(self.token) == "string"
        self.next_token()
        if self.token == "{"
            self.next_token()
            self.field()

            self.token == "}" || error("} missing")
        end
    end
end

"""Field"""
function field(self)
    name = self.name()
    if self.token == '='
        self.next_token()
        value = self.value()
        if self.mode == 'string'
            self.hashtable[name] = value
        end
        return (name, value)
    end
end

"""Value"""
function value(self)
    value = ""
    val = []

    while true
        if self.token == '"'
            while true
                self.next_token()
                if self.token == '"'
                    break
                else
                    push!(val, self.token)
                end
            end
            if self.token == '"'
                self.next_token()
            else
                error("\" missing")
            end
        elseif self.token == '{'
            brac_counter = 0
            while true
                self.next_token()
                if self.token == '{'
                    brac_counter += 1
                end
                if self.token == '}'
                    brac_counter -= 1
                end
                if brac_counter < 0
                    break
                else
                    push!(val, self.token)
                end
            end
            if self.token == '}'
                self.next_token()
            else
                error("} missing")
            end
        elseif self.token != "=" && re.match(r"\w|#|,", self.token)
            value = self.query_hashtable(self.token)
            push!(val, value)
            while true
                self.next_token()
                # if token is in hashtable then replace
                value = self.query_hashtable(self.token)
                if re.match(r"[^\w#]|,|}|{", self.token) #self.token == '' :
                    break
                else
                    push!(val, value)
                end
            end

        elseif self.token.isdigit()
            value = self.token
            self.next_token()
        else
            if self.token in self.hashtable
                value = self.hashtable[ self.token ]
            else
                value = self.token
            end
            self.next_token()
        end

        if re.match(r"}|,", self.token)
            break
        end

    value = join(val, " ")
    return value
end

query_hashtable( self, s ) =
  s in self.hashtable ? self.hashtable[ self.token ] : s

"""Returns parsed Name"""
function name(self)
    name = self.token
    self.next_token()
    return name
end

"""Returns parsed Key"""
function key(self)
    key = self.token
    self.next_token()
    return key
end

"""Record"""
function record(self)
    if !(self.token in ["comment", "string", "preamble"])
        record_type = self.token
        self.next_token()
        if self.token == '{'
            self.next_token()
            key = self.key()
            self.records[ key ] = Dict()
            self.records[ key ]["type"] = record_type
            self.records[ key ]["id"] = key
            if self.token == ","
                while true
                    self.next_token()
                    field = self.field()
                    if field
                        k = field[0]
                        val = field[1]

                        if k == "author"
                            val = self.parse_authors(val)
                        end

                        if k == "year"
                            val = Dict("literal" => val)
                            k = "issued"
                        end

                        if k == "pages"
                            val = replace(val, "--" => "-")
                            k = "page"
                        end

                        if k == "title"
                            #   Preserve capitalization, as described in http://tex.stackexchange.com/questions/7288/preserving-capitalization-in-bibtex-titles
                            #   This will likely choke on nested curly-brackets, but that doesn't seem like an ordinary practice.
                            function capitalize(s)
                                return s.group(1)*uppercase(s.group(2))
                            end
                            while val.find('{') > -1
                                caps = (val.find('{'), val.find('}'))
                                val = val.replace(val[caps[0]:caps[1]+1], re.sub("(^|\s)(\S)", capitalize, val[caps[0]+1:caps[1]]).strip())
                            end

                        self.records[ key ][k] = val
                    end
                    self.token == "," || break
                end
                if self.token != "}" && self.token != "@"
                    error("@ missing")
                end
            end
        end
    end
end

function parse_authors(self, authors)
    res = []
    authors = split(authors, "and")
    for author in authors
        _author = split(author, ",")
        family = rstrip(strip(_author[0]))
        rec = Dict("family" => family)
        try
            given = rstrip(strip(_author[1]))
            rec["given"] = given
        catch
        end
        push!(res, rec)
    end
    return res
end

"""Returns json formated records"""
json(self) = JSON.dumps(Dict("items"=>self.records.values()))

