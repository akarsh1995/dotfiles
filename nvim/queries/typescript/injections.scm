;; SQL with parameter/prop (e.g., gql(param)`query { users { id } }`)
(
  (call_expression
    function: (call_expression
      function: (identifier) @_name
      (#eq? @_name "sql")
    )
  )
  (template_string) @injection.content
  (#set! injection.language "sql")
  (#set! injection.include-children)
)

;; Match any other *.query() methods with string arguments
((call_expression
  function: (member_expression
    property: (property_identifier) @_prop)
  arguments: (arguments (string) @injection.content))
 (#eq? @_prop "query")
 (#set! injection.language "sql")
 (#set! injection.include-children)
 )

;; SQL direct tag injection (sql`SELECT * FROM table`)
(
  (call_expression
    function: (identifier) @_name
    (#eq? @_name "sql")
  )
  (template_string) @injection.content
  (#set! injection.language "sql")
  (#set! injection.include-children)
)

;; SQL member expression (e.g., db.sql`SELECT * FROM table`)
(
  (call_expression
    function: (member_expression
      property: (property_identifier) @_prop
      (#eq? @_prop "sql")
    )
  )
  (template_string) @injection.content
  (#set! injection.language "sql")
  (#set! injection.include-children)
)

;; SQL as member expression itself (e.g., sql.query`SELECT * FROM table`)
(
  (call_expression
    function: (member_expression
      object: (identifier) @_obj
      (#eq? @_obj "sql")
    )
  )
  (template_string) @injection.content
  (#set! injection.language "sql")
  (#set! injection.include-children)
)

