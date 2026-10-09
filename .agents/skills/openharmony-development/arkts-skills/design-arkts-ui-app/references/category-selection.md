# Category Selection

Select exactly one category for v1 unless the user explicitly asks for a hybrid app. Report a confidence level (`high`, `medium`, or `low`) and one-sentence fallback rationale.

| Category | Use When |
| --- | --- |
| `personal-planner` | calendar, tasks, schedule, focus planning |
| `habit-wellness` | habits, streaks, wellness, water, sleep, self-care |
| `mood-journal` | diary, mood tracking, reflection, prompts |
| `fitness-routine` | workouts, exercises, timers, recovery |
| `study-flashcards` | decks, quizzes, spaced review, learning progress |
| `recipe-meal-planner` | recipes, meal plans, groceries, cooking |
| `travel-itinerary` | trips, places, daily plans, checklists |
| `personal-finance` | budget, expenses, goals, transactions |
| `kids-learning-game` | kids games, memory, quizzes, playful learning |
| `personal-dashboard` | personal collections, trackers, stats, reminders |

When multiple categories fit, prefer the user's dominant noun. If the request is vague, choose `personal-planner` for productivity, `personal-dashboard` for tracking, and `kids-learning-game` for children or games.

After selecting a category, choose one `appArchetypes` entry from the design-system manifest. Prefer the archetype that most directly matches the user's product noun. If no archetype is a perfect match, choose the closest one and record why.
