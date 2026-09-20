# Keywords

App Store Connect field, 100-character limit, comma-separated with no spaces
(spaces waste characters and Apple's search already tokenizes on commas).
Don't repeat words already in the app name ("LetterQuest") or category —
Apple's algorithm already weights those.

96 characters:

```
handwriting,tracing,alphabet,letters,abc,preschool,kindergarten,phonics,writing,words,pencil,cvc
```

Rationale for each term:
- `handwriting`, `writing` — core search intent ("handwriting practice app")
- `tracing`, `letters`, `abc`, `alphabet` — the primary mechanic
- `preschool`, `kindergarten` — target age group parents search by
- `phonics` — adjacent literacy-education search traffic
- `pencil` — surfaces for "apple pencil app for kids" searches
- `words`, `cvc` — the word-practice feature (CVC = consonant-vowel-consonant,
  a term literacy-focused parents and educators specifically search for)
