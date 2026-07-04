#!/usr/bin/env bash
set -e
# ============================================================
# basicRebrand.sh - Rebrand BSC genesis contracts to custom chain
# ============================================================
# Usage: ./basicRebrand.sh --name Dorsen --symbol DC
# ============================================================
# --- Parse arguments ---
OLD_NAME="BSC"
OLD_SYMBOL="BNB"
GOV_TOKEN_OLD_NAME="BSC Governance Token"
GOV_TOKEN_OLD_SYMBOL="govBNB"
PROJECT_OLD_NAME="bsc-genesis-contract"
while [[ $# -gt 0 ]]; do
  case $1 in
    --name) NEW_NAME="$2"; shift 2 ;;
    --symbol) NEW_SYMBOL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done
if [ -z "$NEW_NAME" ] || [ -z "$NEW_SYMBOL" ]; then
  echo "Usage: $0 --name <BlockchainName> --symbol <CoinSymbol>"
  echo "Example: $0 --name Dorsen --symbol DC"
  exit 1
fi
GOV_TOKEN_NEW_NAME="${NEW_NAME} Governance Token"
GOV_TOKEN_NEW_SYMBOL="gov${NEW_SYMBOL}"
PROJECT_NEW_NAME="$(echo "$NEW_NAME" | tr '[:upper:]' '[:lower:]')-genesis-contract"
OLD_NAME_LOWER="$(echo "$OLD_NAME" | tr '[:upper:]' '[:lower:]')"
NEW_NAME_LOWER="$(echo "$NEW_NAME" | tr '[:upper:]' '[:lower:]')"
echo "Rebranding: ${OLD_NAME} -> ${NEW_NAME}"
echo "Symbol:     ${OLD_SYMBOL} -> ${NEW_SYMBOL}"
echo "GovToken:   ${GOV_TOKEN_OLD_NAME} -> ${GOV_TOKEN_NEW_NAME}"
echo "GovSymbol:  ${GOV_TOKEN_OLD_SYMBOL} -> ${GOV_TOKEN_NEW_SYMBOL}"
echo "Project:    ${PROJECT_OLD_NAME} -> ${PROJECT_NEW_NAME}"
echo ""
# ============================================================
# STEP 1: Replace ALL BSC* names inside ALL .sol files
# ============================================================
echo "Step 1: Replacing all BSC references inside .sol files..."
# Specific string replacements first
find contracts/ test/ -name "*.sol" -exec sed -i '' \
  -e "s/__Governor_init(\"${OLD_NAME}Governor\")/__Governor_init(\"${NEW_NAME}Governor\")/g" \
  -e "s/\"${GOV_TOKEN_OLD_NAME}\"/\"${GOV_TOKEN_NEW_NAME}\"/g" \
  -e "s/\"${GOV_TOKEN_OLD_SYMBOL}\"/\"${GOV_TOKEN_NEW_SYMBOL}\"/g" \
  -e "s/gov${OLD_SYMBOL}/gov${NEW_SYMBOL}/g" \
  -e "s/PROPOSE_START_GOV${OLD_SYMBOL}_SUPPLY_THRESHOLD/PROPOSE_START_GOV${NEW_SYMBOL}_SUPPLY_THRESHOLD/g" \
  -e "s/${OLD_NAME_LOWER}ValidatorSet/${NEW_NAME_LOWER}ValidatorSet/g" \
  {} +
# Catch-all: replace ALL remaining BSC* references
# Order: longer strings first to avoid substring issues
find contracts/ test/ -name "*.sol" -exec sed -i '' \
  -e "s/I${OLD_NAME}ValidatorSetV2/I${NEW_NAME}ValidatorSetV2/g" \
  -e "s/I${OLD_NAME}ValidatorSet/I${NEW_NAME}ValidatorSet/g" \
  -e "s/${OLD_NAME}ValidatorSetTool/${NEW_NAME}ValidatorSetTool/g" \
  -e "s/${OLD_NAME}ValidatorSet/${NEW_NAME}ValidatorSet/g" \
  -e "s/${OLD_NAME}Governor/${NEW_NAME}Governor/g" \
  -e "s/${OLD_NAME}Timelock/${NEW_NAME}Timelock/g" \
  {} +
echo "  Done."
# ============================================================
# STEP 2: Rename .sol filenames
# ============================================================
echo "Step 2: Renaming .sol filenames..."
git mv contracts/${OLD_NAME}Governor.sol contracts/${NEW_NAME}Governor.sol 2>/dev/null || true
git mv contracts/${OLD_NAME}ValidatorSet.sol contracts/${NEW_NAME}ValidatorSet.sol 2>/dev/null || true
git mv contracts/${OLD_NAME}Timelock.sol contracts/${NEW_NAME}Timelock.sol 2>/dev/null || true
git mv contracts/extension/${OLD_NAME}ValidatorSetTool.sol contracts/extension/${NEW_NAME}ValidatorSetTool.sol 2>/dev/null || true
git mv contracts/interface/0.6.x/I${OLD_NAME}ValidatorSet.sol contracts/interface/0.6.x/I${NEW_NAME}ValidatorSet.sol 2>/dev/null || true
git mv contracts/interface/0.8.x/I${OLD_NAME}ValidatorSet.sol contracts/interface/0.8.x/I${NEW_NAME}ValidatorSet.sol 2>/dev/null || true
git mv contracts/interface/0.6.x/I${OLD_NAME}ValidatorSetV2.sol contracts/interface/0.6.x/I${NEW_NAME}ValidatorSetV2.sol 2>/dev/null || true
git mv test/utils/interface/I${OLD_NAME}Governor.sol test/utils/interface/I${NEW_NAME}Governor.sol 2>/dev/null || true
git mv test/utils/interface/I${OLD_NAME}ValidatorSet.sol test/utils/interface/I${NEW_NAME}ValidatorSet.sol 2>/dev/null || true
git mv test/utils/interface/I${OLD_NAME}Timelock.sol test/utils/interface/I${NEW_NAME}Timelock.sol 2>/dev/null || true
git mv test/utils/interface/I${OLD_NAME}ValidatorSetTool.sol test/utils/interface/I${NEW_NAME}ValidatorSetTool.sol 2>/dev/null || true
echo "  Done."
# ============================================================
# STEP 3: Update import paths
# ============================================================
echo "Step 3: Updating import paths..."
sed -i '' \
  "s|./interface/0.6.x/I${OLD_NAME}ValidatorSet.sol|./interface/0.6.x/I${NEW_NAME}ValidatorSet.sol|g" \
  contracts/${NEW_NAME}ValidatorSet.sol \
  contracts/SlashIndicator.sol
sed -i '' \
  "s|./interface/0.8.x/I${OLD_NAME}ValidatorSet.sol|./interface/0.8.x/I${NEW_NAME}ValidatorSet.sol|g" \
  contracts/StakeHub.sol
sed -i '' \
  "s|./interface/0.6.x/I${OLD_NAME}ValidatorSetV2.sol|./interface/0.6.x/I${NEW_NAME}ValidatorSetV2.sol|g" \
  contracts/deprecated/CrossChain.sol 2>/dev/null || true
sed -i '' \
  -e "s|./interface/I${OLD_NAME}ValidatorSet.sol|./interface/I${NEW_NAME}ValidatorSet.sol|g" \
  -e "s|./interface/I${OLD_NAME}Governor.sol|./interface/I${NEW_NAME}Governor.sol|g" \
  -e "s|./interface/I${OLD_NAME}Timelock.sol|./interface/I${NEW_NAME}Timelock.sol|g" \
  test/utils/Deployer.sol
sed -i '' \
  "s|./utils/interface/I${OLD_NAME}ValidatorSetTool.sol|./utils/interface/I${NEW_NAME}ValidatorSetTool.sol|g" \
  test/ValidatorSetTool.t.sol 2>/dev/null || true
echo "  Done."
# ============================================================
# STEP 4: Update test/utils/Deployer.sol
# ============================================================
echo "Step 4: Updating Deployer.sol..."
# Type declarations and cast calls
sed -i '' \
  -e "s/${OLD_NAME}ValidatorSet public /${NEW_NAME}ValidatorSet public /g" \
  -e "s/${OLD_NAME}Governor public /${NEW_NAME}Governor public /g" \
  -e "s/${OLD_NAME}Timelock public /${NEW_NAME}Timelock public /g" \
  -e "s/${OLD_NAME}ValidatorSet(VALIDATOR_CONTRACT_ADDR)/${NEW_NAME}ValidatorSet(VALIDATOR_CONTRACT_ADDR)/g" \
  -e "s/${OLD_NAME}Governor(GOVERNOR_ADDR)/${NEW_NAME}Governor(GOVERNOR_ADDR)/g" \
  -e "s/${OLD_NAME}Timelock(TIMELOCK_ADDR)/${NEW_NAME}Timelock(TIMELOCK_ADDR)/g" \
  test/utils/Deployer.sol
# Variable name lowercase
sed -i '' \
  "s/${OLD_NAME_LOWER}ValidatorSet/${NEW_NAME_LOWER}ValidatorSet/g" \
  test/utils/Deployer.sol
# vm.label and vm.getDeployedCode
sed -i '' \
  -e "s/vm\.label(address(${NEW_NAME_LOWER}ValidatorSet), \"${OLD_NAME}ValidatorSet\")/vm.label(address(${NEW_NAME_LOWER}ValidatorSet), \"${NEW_NAME}ValidatorSet\")/g" \
  -e "s/vm\.label(address(governor), \"${OLD_NAME}Governor\")/vm.label(address(governor), \"${NEW_NAME}Governor\")/g" \
  -e "s/vm\.label(address(timelock), \"${OLD_NAME}Timelock\")/vm.label(address(timelock), \"${NEW_NAME}Timelock\")/g" \
  -e "s/vm\.getDeployedCode(\"${OLD_NAME}ValidatorSet\.sol:${OLD_NAME}ValidatorSet\")/vm.getDeployedCode(\"${NEW_NAME}ValidatorSet.sol:${NEW_NAME}ValidatorSet\")/g" \
  -e "s/vm\.getDeployedCode(\"${OLD_NAME}Governor\.sol:${OLD_NAME}Governor\")/vm.getDeployedCode(\"${NEW_NAME}Governor.sol:${NEW_NAME}Governor\")/g" \
  -e "s/vm\.getDeployedCode(\"${OLD_NAME}Timelock\.sol:${OLD_NAME}Timelock\")/vm.getDeployedCode(\"${NEW_NAME}Timelock.sol:${NEW_NAME}Timelock\")/g" \
  test/utils/Deployer.sol
echo "  Done."
# ============================================================
# STEP 5: Update remaining test files
# ============================================================
echo "Step 5: Updating test files..."
sed -i '' \
  -e "s/${OLD_NAME}Governor\.InBlackList/${NEW_NAME}Governor.InBlackList/g" \
  -e "s/${OLD_NAME}Governor\._castVote/${NEW_NAME}Governor._castVote/g" \
  test/GovernorBlacklistBySig.t.sol 2>/dev/null || true
sed -i '' \
  -e "s/${OLD_NAME}ValidatorSetTool/${NEW_NAME}ValidatorSetTool/g" \
  -e "s/${OLD_NAME}ValidatorSetTool\.sol/${NEW_NAME}ValidatorSetTool.sol/g" \
  test/ValidatorSetTool.t.sol 2>/dev/null || true
echo "  Done."
# ============================================================
# STEP 6: Update scripts/generate.py
# ============================================================
echo "Step 6: Updating scripts/generate.py..."
sed -i '' \
  -e "s|\"${OLD_NAME}Governor.sol\"|\"${NEW_NAME}Governor.sol\"|g" \
  -e "s|\"${OLD_NAME}Timelock.sol\"|\"${NEW_NAME}Timelock.sol\"|g" \
  -e "s|\"${OLD_NAME}ValidatorSet.sol\"|\"${NEW_NAME}ValidatorSet.sol\"|g" \
  -e "s/of ${OLD_NAME}Governor\"/of ${NEW_NAME}Governor\"/g" \
  -e "s/of ${OLD_NAME}Timelock\"/of ${NEW_NAME}Timelock\"/g" \
  -e "s/of ${OLD_NAME}ValidatorSet\"/of ${NEW_NAME}ValidatorSet\"/g" \
  -e "s/of ${OLD_NAME}ValidatorSet,/of ${NEW_NAME}ValidatorSet,/g" \
  scripts/generate.py
echo "  Done."
# ============================================================
# STEP 7: Update scripts/generate-genesis.js
# ============================================================
echo "Step 7: Updating scripts/generate-genesis.js..."
sed -i '' \
  -e "s|out/${OLD_NAME}ValidatorSet.sol/${OLD_NAME}ValidatorSet.json|out/${NEW_NAME}ValidatorSet.sol/${NEW_NAME}ValidatorSet.json|g" \
  -e "s|out/${OLD_NAME}Governor.sol/${OLD_NAME}Governor.json|out/${NEW_NAME}Governor.sol/${NEW_NAME}Governor.json|g" \
  -e "s|out/${OLD_NAME}Timelock.sol/${OLD_NAME}Timelock.json|out/${NEW_NAME}Timelock.sol/${NEW_NAME}Timelock.json|g" \
  scripts/generate-genesis.js
echo "  Done."
# ============================================================
# STEP 8: Update scripts/flatten.sh (both input AND output paths)
# ============================================================
echo "Step 8: Updating scripts/flatten.sh..."
sed -i '' \
  -e "s|${OLD_NAME}ValidatorSet|${NEW_NAME}ValidatorSet|g" \
  -e "s|${OLD_NAME}Governor|${NEW_NAME}Governor|g" \
  -e "s|${OLD_NAME}Timelock|${NEW_NAME}Timelock|g" \
  scripts/flatten.sh
echo "  Done."
# ============================================================
# STEP 9: Update project files
# ============================================================
echo "Step 9: Updating project files..."
sed -i '' \
  "s/${PROJECT_OLD_NAME}/${PROJECT_NEW_NAME}/g" \
  package.json pyproject.toml
sed -i '' \
  -e "s|./contracts/${OLD_NAME}Timelock.sol|./contracts/${NEW_NAME}Timelock.sol|g" \
  -e "s|./contracts/${OLD_NAME}Governor.sol|./contracts/${NEW_NAME}Governor.sol|g" \
  package.json
sed -i '' \
  "s/authors = \[\"BNB Chain\"\]/authors = [\"${NEW_NAME}\"]/g" \
  pyproject.toml
echo "  Done."
# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "============================================"
echo "Rebrand complete: ${OLD_NAME} -> ${NEW_NAME}"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Run 'forge build' to verify compilation"
echo "  2. Commit changes"