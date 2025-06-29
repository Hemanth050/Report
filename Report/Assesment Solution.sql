
/*"Final Loyalty Point Formula
Loyalty Point = (0.01 * deposit) + (0.005 * Withdrawal amount) + (0.001 * (maximum of (#deposit - #withdrawal) or 0)) + (0.2 * Number of games played)
At the end of each month total loyalty points are alloted to all the players. Out of which the top 50 players are provided cash benefits."	*/														

WITH 
agg_gameplay AS (
  SELECT `User ID`, SUM(`Games Played`) AS games_played
  FROM user_gameplay
  GROUP BY `User ID`
),
agg_deposit AS (
  SELECT `User Id`, SUM(`Amount`) AS deposit_sum, COUNT(*) AS deposit_count
  FROM deposit_data
  GROUP BY `User Id`
),
agg_withdrawal AS (
  SELECT `User Id`, SUM(`Amount`) AS withdraw_sum, COUNT(*) AS withdraw_count
  FROM withdrawal_data
  GROUP BY `User Id`
),
Loyality_Points AS (
  SELECT 
    ug.`User ID`,
    (0.01 * IFNULL(d.deposit_sum, 0)) +
    (0.005 * IFNULL(w.withdraw_sum, 0)) +
    (0.001 * (IFNULL(d.deposit_count, 0) - IFNULL(w.withdraw_count, 0))) +
    (0.2 * IFNULL(ug.games_played, 0)) AS Loyality_Points
  FROM agg_gameplay ug
  LEFT JOIN agg_deposit d ON ug.`User ID` = d.`User Id`
  LEFT JOIN agg_withdrawal w ON ug.`User ID` = w.`User Id`
)
SELECT * 
FROM Loyality_Points
order by `User ID`

/*"Part A - Calculating loyalty points
On each day, there are 2 slots for each of which the loyalty points are to be calculated:
S1 from 12am to 12pm 
S2 from 12pm to 12am"*/

CREATE TABLE session_points AS 
SELECT
  ug.`User ID`,
  ug.`Datetime`,
  p.`Loyality_Points`,
  CASE 
    WHEN HOUR(STR_TO_DATE(ug.`Datetime`, '%d-%m-%Y %H:%i')) >= 0 
         AND HOUR(STR_TO_DATE(ug.`Datetime`, '%d-%m-%Y %H:%i')) < 12 THEN 'S1'
    ELSE 'S2'
  END AS Session
FROM user_gameplay ug
LEFT JOIN points p ON ug.`User ID` = p.`User ID`;

/*1. Find Playerwise Loyalty points earned by Players in the following slots:-
    a. 2nd October Slot S1 */
    
Create table oct_2nd_s1 as
SELECT *
FROM session_points
WHERE 
  DATE(STR_TO_DATE(`Datetime`, '%d-%m-%Y %H:%i')) = '2022-10-02'
  AND UPPER(TRIM(Session)) = 'S1';
  
-- b. 16th October Slot S2

Create table oct_16th_s2 as 
SELECT *
FROM session_points
WHERE 
  DATE(STR_TO_DATE(`Datetime`, '%d-%m-%Y %H:%i')) = '2022-10-16'
  AND UPPER(TRIM(Session)) = 'S2'
  
--     b. 18th October Slot S1

Create table oct_18th_s1 as 
SELECT *
FROM session_points
WHERE 
  DATE(STR_TO_DATE(`Datetime`, '%d-%m-%Y %H:%i')) = '2022-10-18'
  AND UPPER(TRIM(Session)) = 'S1';
  
-- b. 26th October Slot S2

Create table oct_26th_s2 as 
SELECT *
FROM session_points
WHERE 
  DATE(STR_TO_DATE(`Datetime`, '%d-%m-%Y %H:%i')) = '2022-10-26'
  AND UPPER(TRIM(Session)) = 'S2';

/*2. Calculate overall loyalty points earned and rank players on the basis of loyalty points in the month of October. 
     In case of tie, number of games played should be taken as the next criteria for ranking.*/

create table Over_all_Loyaity_Points
select round(sum(Loyality_Points),1) as Over_all_Loyaity_Points from session_points




create table rnk_players_onpoints
SELECT 
  distinct `User ID`,
  `Loyality_Points`,
  dense_rank() OVER (ORDER BY `Loyality_Points` DESC) AS rnk
FROM session_points
where date(str_to_date(`Datetime`,'%d-%m-%Y %H:%i')) between '2022-10-1' and '2022-10-31'

-- 3. What is the average deposit amount?

create table Average_deposit_data
select 
	Avg(Amount) as Average_deposit
from 
deposit_data

-- 4. What is the average deposit amount per user in a month?


create table avg_depossit_data
SELECT 
  `User Id`,
  DATE_FORMAT(STR_TO_DATE(`Datetime`, '%d-%m-%Y %H:%i'), '%Y-%m') AS Month,
  AVG(`Amount`) AS Avg_Deposit_Per_User
FROM deposit_data
GROUP BY `User Id`, Month
ORDER BY `User Id`, Month;

-- 5. What is the average number of games played per user?

create table  Avg_Games_Played_Per_User
SELECT 
  AVG(games_per_user) AS Avg_Games_Played_Per_User
FROM (
  SELECT `User ID`, SUM(`Games Played`) AS games_per_user
  FROM user_gameplay
  GROUP BY `User ID`
) AS user_games;

/*"Part B - How much bonus should be allocated to leaderboard players?

After calculating the loyalty points for the whole month find out which 50 players are at the top of the leaderboard. The company has allocated a pool of Rs 50000 to be given away as bonus money to the loyal players.

Now the company needs to determine how much bonus money should be given to the players.

Should they base it on the amount of loyalty points? Should it be based on number of games? Or something else?

That’s for you to figure out.

Suggest a suitable way to divide the allocated money keeping in mind the following points:
1. Only top 50 ranked players are awarded bonus */

create table Bonus_for_Top50
SELECT 
  `User ID`,
  `Loyality_Points`,
  `rnk`,
  ROUND((`Loyality_Points` / SUM(`Loyality_Points`) OVER ()) * 50000, 0) AS bonus
FROM rnk_players_onpoints
WHERE `rnk` <= 50
ORDER BY bonus DESC;



/*Part C

Would you say the loyalty point formula is fair or unfair?

Can you suggest any way to make the loyalty point formula more robust?"	*/																	

 Use net deposit: reward (deposit - withdrawal)

 Add engagement: include active days

Cap extreme values: avoid big outlier impact

 Balance weights: slightly increase games played weight
 Loyalty = 0.008 * (deposit - withdrawal) + 
          0.001 * (deposit_count - withdraw_count) + 
          0.15 * games_played + 
          0.1 * active_days


