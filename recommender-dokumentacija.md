# EscapeHub recommender

## Purpose

The recommender shows a client the escape rooms that the client will probably like. The mobile application shows the result on the home screen. Each recommendation has a text that tells the client why the room is on the list.

The recommender uses content-based filtering with a weighted score. It also uses the popularity and the rating of a room. It does not use random values. The same data always gives the same order.

## Endpoint

`GET /api/recommendations/me?page=1&pageSize=5`

- Role: `Client`.
- `page`: 1 or more. The default value is 1.
- `pageSize`: 1-20. The default value is 5.
- Response: a `PagedResult` of `RecommendationDto` (`items`, `totalCount`, `page`, `pageSize`, `totalPages`). Each item has the room data, `score` (0-100), `alreadyPlayed` and `reason`.

The code is in `src/EscapeHub.Infrastructure/Services/RecommendationService.cs`.

## Input data

The recommender reads only data that the application writes during normal use:

| Data | Source | Written when |
| --- | --- | --- |
| Completed sessions of the client (room, theme, difficulty, number of players) | `Bookings` with the status `Completed` | Staff completes a booking |
| Ratings of the client | `Reviews` | The client writes or edits a review |
| Bookings of each room that clients created in the last 90 days | `Bookings` (not `Cancelled`, not `Rejected`), filtered on `CreatedAt` | Any client makes a booking |
| Average rating and number of reviews of each room | `Reviews` that are not hidden | Clients write reviews, staff hides or shows reviews |

The recommender uses only active rooms.

## Client profile

The recommender makes a profile from the completed sessions and the reviews of the client.

### Session weight

Each completed session gets a weight from the rating that the client gave to the room:

| Rating of the room | Weight |
| --- | --- |
| No rating | 1 |
| 5 | 2 |
| 4 | 1.5 |
| 3 | 0.5 |
| 1 or 2 | -1 |

A room that the client did not like reduces the interest in its theme.

### Theme interest

For each theme, the recommender adds the weights of the sessions in that theme. The theme with the highest sum gets the value 1. The other themes get `sum / highest sum`. A negative value becomes 0.

### Preferred difficulty

The preferred difficulty is the weighted average of the difficulty values of the sessions with a positive weight. The difficulty values are: Easy 1, Medium 2, Hard 3, Expert 4.

### Usual group size

The usual group size is the median of the number of players in the completed sessions. For an even number of sessions, the recommender uses the higher of the two middle values.

### Played rooms

A played room is a room with a completed session or a review from the client.

## Signals and weights

The recommender calculates five signals for each room. Each signal has a value from 0 to 1.

| Signal | Weight | Formula |
| --- | --- | --- |
| Theme | 0.35 | The theme interest of the room theme |
| Difficulty | 0.20 | `max(0, 1 - abs(room difficulty - preferred difficulty) / 4)`. The value is 0 if the client has no positive session. |
| Group size | 0.10 | 1 if the usual group size is between the minimum and the maximum players of the room. Else 0. |
| Popularity | 0.15 | `bookings of the room created in the last 90 days / highest number of such bookings of one room` |
| Rating | 0.20 | `smoothed rating / 5` |

The smoothed rating prevents a room with one review from getting a high score too easily:

`smoothed rating = (average rating * number of reviews + 3.5 * 2) / (number of reviews + 2)`

A room with no reviews gets 3.5.

### Score

`score = 0.35 * theme + 0.20 * difficulty + 0.10 * group + 0.15 * popularity + 0.20 * rating`

If the client played the room before, the recommender multiplies the score by 0.5. The response shows `score * 100`, rounded to one decimal.

### Order

1. Rooms that the client did not play come first.
2. In each group, a higher score comes first.
3. For the same score, a lower room ID comes first.

The recommender sorts all active rooms in this order. The response contains the rooms of the requested page.

### New client

A client with no completed session has no theme, difficulty or group signal. The score then comes only from popularity and rating. Thus a new client sees the popular rooms with good ratings.

## Explanation text

The `reason` field joins these sentences, in this order. A sentence is added only when its condition is true.

| Condition | Sentence |
| --- | --- |
| The client played the room | "You played this room before, but it still matches your taste" |
| Theme signal is 0.5 or more, or difficulty signal is 0.75 or more | "Because you liked Mystery and Medium rooms" (the theme, the difficulty, or both) |
| Group signal is 1 | "Fits your usual group of 4 players" |
| The room has reviews and an average rating of 4 or more | "Rated 4.3 out of 5 in 3 reviews" |
| Popularity signal is 0.9 or more | "One of the most popular rooms" |
| No other sentence applies | "A new room for you to try" |

## Example

This example uses the seed data for the user `mobile`.

Completed sessions:

| Room | Theme | Difficulty | Players | Rating | Weight |
| --- | --- | --- | --- | --- | --- |
| The Deep Stone Crypt | Sci-Fi | Hard (3) | 4 | No rating | 1 |
| Cauldron Lake | Mystery | Medium (2) | 3 | 3 | 0.5 |
| Oh Deer Diner | Adventure | Easy (1) | 4 | 4 | 1.5 |

Profile:

- Theme interest: Adventure 1, Sci-Fi `1 / 1.5 = 0.667`, Mystery `0.5 / 1.5 = 0.333`.
- Preferred difficulty: `(3 * 1 + 2 * 0.5 + 1 * 1.5) / (1 + 0.5 + 1.5) = 1.833`.
- Usual group size: the median of 3, 4 and 4 is 4.

Score of "The Whisper" (Mystery, Expert (4), 2-4 players, 25 bookings in 90 days, one review with the rating 4). The most booked room ("The Deep Stone Crypt") has 32 bookings. The seed makes the bookings relative to the current date, so these counts can change by one or two after a new seed.

| Signal | Value | Weighted |
| --- | --- | --- |
| Theme | 0.333 | 0.1167 |
| Difficulty | `1 - 2.167 / 4 = 0.458` | 0.0917 |
| Group size | 1 | 0.1 |
| Popularity | `25 / 32 = 0.781` | 0.1172 |
| Rating | `((4 * 1 + 3.5 * 2) / 3) / 5 = 0.733` | 0.1467 |
| Total | | 0.5722 |

The API returns `score: 57.2` and the reason "Fits your usual group of 4 players. Rated 4.0 out of 5 in 1 review." The theme signal is less than 0.5 and the difficulty signal is less than 0.75, so the reason does not contain a "Because you liked" sentence. The result of `GET /api/recommendations/me` for the user `mobile` after a new seed agrees with this calculation.

"Oh Deer Diner" has a high base score, but the client played it. Its score is multiplied by 0.5, and it comes after all the rooms that the client did not play.

## Limits

- The recommender does not use the search history of the client.
- The recommender calculates the score for each request. It does not keep a model.
- The weights are constants in `RecommendationService`. A change of a weight needs a change of this document.
