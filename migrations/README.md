Create your initial migration with goose. Goose supports raw SQL or Golang source files. You may choose golang, but this template assumes sql.

To create the migration, navigate to this directory, and execute:
`goose create init sql`

The generated sql will include annotations like this:

`-- +goose StatementBegin`
`-- +goose StatementEnd`

If your SQL is just straighforward CREATE statements, terminated with Semicolons, you can deleted these. Otherwise, every statement will need to start and end with those annotations.
