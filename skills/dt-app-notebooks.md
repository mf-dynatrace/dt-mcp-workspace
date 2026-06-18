# Dynatrace Notebook Skill
> Source: [Dynatrace/dynatrace-for-ai](https://github.com/Dynatrace/dynatrace-for-ai) — `dt-app-notebooks`

Create, modify, query, and analyze Dynatrace notebooks.

---

## Notebook Structure

```json
{
  "name": "Production Investigation",
  "type": "notebook",
  "content": {
    "version": "7",
    "defaultTimeframe": { "from": "now()-2h", "to": "now()" },
    "sections": []
  }
}
```

### Sections

**Markdown sections:** `{"type": "markdown", "markdown": "# Content"}`
**DQL sections:** `{"type": "dql", "state": {"input": {"value": "query"}, "visualization": "table"}}`

**Visualizations:** `table`, `lineChart`, `barChart`, `pieChart`, `singleValue`, `areaChart`

---

## Notebook Types

- **Investigation**: Markdown context → DQL queries → Analysis → Findings
- **Documentation**: Narrative with embedded queries
- **Query Library**: Collection of reusable DQL patterns with explanations

---

## Best Practices

- Use unique UUIDs for section IDs
- Start with markdown context
- Set content version="7"
- Use relative timeframes (`now()-2h`)
- Omit result objects when creating sections
- Order sections logically
- Add markdown between query sections for context
