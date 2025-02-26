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
