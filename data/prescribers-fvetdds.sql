---## Prescribers Database

---For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

---1. 
---    a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) as claim_no
FROM prescription 
INNER JOIN prescriber
USING(npi)
GROUP BY npi
ORDER BY claim_no DESC;
    
---b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT pr.npi, p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description, SUM(total_claim_count) as claim_no
FROM prescription AS pr
INNER JOIN prescriber AS p
USING(npi)
GROUP BY pr.npi, p.nppes_provider_first_name, p.nppes_provider_last_org_name, p.specialty_description
ORDER BY claim_no DESC;
---2. 
---    a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT p.specialty_description, SUM(total_claim_count) as claim_no
FROM prescription AS pr
INNER JOIN prescriber AS p
USING(npi)
GROUP BY p.specialty_description
ORDER BY claim_no DESC;

---b. Which specialty had the most total number of claims for opioids?
SELECT p.specialty_description, pr.drug_name, COUNT(d.opioid_drug_flag) AS opioid_claim
FROM prescription AS pr
INNER JOIN prescriber AS p
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
WHERE d.opioid_drug_flag <> 'N'
GROUP BY p.specialty_description, pr.drug_name
ORDER BY opioid_claim DESC;

---c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT pr.specialty_description, pr.nppes_provider_first_name, pr.nppes_provider_last_org_name
FROM prescriber AS pr
LEFT JOIN prescription AS p
USING(npi)
WHERE p.npi IS NULL; 

---d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT pr.specialty_description, SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN p.total_claim_count ELSE 0 END) AS opioid_claim,
	SUM(p.total_claim_count) AS total_claim,
	ROUND(100 * SUM(CASE WHEN d.opioid_drug_flag = 'Y' THEN p.total_claim_count ELSE 0 END)/NULLIF(SUM(p.total_claim_count), 0), 2) AS opioid_percentage
	FROM prescriber AS pr
	INNER JOIN prescription AS p
	USING(npi)
	INNER JOIN drug AS d
	USING(drug_name)
	GROUP BY pr.specialty_description
	ORDER BY opioid_percentage DESC;
---3. 
---    a. Which drug (generic_name) had the highest total drug cost? Insulin
SELECT d.generic_name, SUM(p.total_drug_cost) as drug_cost
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
GROUP BY d.generic_name
ORDER BY drug_cost DESC
LIMIT 1;
---b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT d.generic_name, ROUND(SUM(p.total_drug_cost)/NULLIF(SUM(p.total_day_supply),0),2) AS cost_per_day
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
GROUP BY d.generic_name
ORDER BY cost_per_day DESC
LIMIT 1;
---4. 
---    a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT drug_name, 
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type
FROM drug;

---b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	CASE
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type,
		SUM(p.total_drug_cost)::MONEY AS total_cost
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;
---5. 
---    a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT c.cbsa) AS tn_num_cbsa
FROM cbsa AS c
INNER JOIN fips_county AS f
USING(fipscounty)
WHERE f.state = 'TN';
---b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT c.cbsa, c.cbsaname, SUM(p.population) AS total_population
FROM cbsa AS c
INNER JOIN population AS p
USING(fipscounty)
GROUP BY c.cbsa, c.cbsaname
ORDER BY total_population DESC
LIMIT 1;
SELECT c.cbsa, c.cbsaname, SUM(p.population) AS total_population
FROM cbsa AS c
INNER JOIN population AS p
USING(fipscounty)
GROUP BY c.cbsa, c.cbsaname
ORDER BY total_population
LIMIT 1;
---c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT f.county, p.population 
FROM fips_county AS f
INNER JOIN population AS p
USING(fipscounty)
LEFT JOIN cbsa AS c
USING(fipscounty)
WHERE c.fipscounty IS NULL
ORDER BY p.population DESC
LIMIT 1;
---6. 
---    a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT d.drug_name, p.total_claim_count
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
WHERE p.total_claim_count >= 3000;
---b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT d.drug_name, p.total_claim_count,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'other'
		END AS opioid_drug
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
WHERE p.total_claim_count >= 3000;
---c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT d.drug_name, p.total_claim_count,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'other'
		END AS opioid_drug,
		pr.nppes_provider_first_name, pr.nppes_provider_last_org_name
FROM drug AS d
INNER JOIN prescription AS p
USING(drug_name)
LEFT JOIN prescriber AS pr
USING(npi)
WHERE p.total_claim_count >= 3000;

---7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

---    a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT pr.npi, d.drug_name
FROM prescriber AS pr
INNER JOIN prescription AS p
USING(npi)
INNER JOIN drug AS d
USING(drug_name)
WHERE pr.specialty_description = 'Pain Management' 
		AND pr.nppes_provider_city = 'NASHVILLE'
		AND d.opioid_drug_flag = 'Y';

---b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT pr.npi, d.drug_name, SUM(CASE WHEN p.total_claim_count IS NULL THEN 0 ELSE p.total_claim_count END) AS total_claim
FROM prescriber AS pr
CROSS JOIN drug AS d
LEFT JOIN prescription AS p
ON pr.npi = p.npi AND d.drug_name = p.drug_name
WHERE pr.specialty_description = 'Pain Management' 
		AND pr.nppes_provider_city = 'NASHVILLE'
		AND d.opioid_drug_flag = 'Y'
GROUP BY pr.npi, d.drug_name
ORDER BY pr.npi, total_claim DESC;
---c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT pr.npi, d.drug_name, COALESCE(SUM(p.total_claim_count),0) AS total_claim
FROM prescriber AS pr
CROSS JOIN drug AS d
LEFT JOIN prescription AS p
ON pr.npi = p.npi AND d.drug_name = p.drug_name
WHERE pr.specialty_description = 'Pain Management' 
		AND pr.nppes_provider_city = 'NASHVILLE'
		AND d.opioid_drug_flag = 'Y'
GROUP BY pr.npi, d.drug_name
ORDER BY pr.npi, total_claim DESC;