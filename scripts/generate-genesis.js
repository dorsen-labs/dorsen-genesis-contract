const program = require('commander');
const nunjucks = require('nunjucks');
const fs = require('fs');
const web3 = require('web3');

const validators = require('./validators');
const init_holders = require('./init_holders');

program.version('0.0.1');
program.option('-c, --chainId <chainId>', 'chain id', '714');
program.option('-o, --output <output-file>', 'Genesis json file', './genesis.json');
program.option('-t, --template <template>', 'Genesis template json', './genesis-template.json');
program.option('--maxwellTime <time>', 'maxwell fork timestamp');
program.option('--fermiTime <time>', 'fermi fork timestamp');
program.option('--osakaTime <time>', 'osaka fork timestamp');
program.option('--mendelTime <time>', 'mendel fork timestamp');
program.parse(process.argv);

// get byte code from compiled contract
function readByteCode(key, contractFile) {
  return new Promise((resolve, reject) => {
    fs.readFile(`${contractFile}`, 'utf8', (err, data) => {
      if (err) {
        reject(new Error('Error reading file: ' + err.message));
        return;
      }

      try {
        const jsonObj = JSON.parse(data);
        const compiledData = jsonObj['deployedBytecode']['object'];

        resolve({
          key: key,
          compiledData: compiledData,
        });
      } catch (parseError) {
        reject(new Error('Error parsing JSON: ' + parseError.message));
      }
    });
  });
}

// compile files
Promise.all([
  readByteCode('validatorContract', 'out/BSCValidatorSet.sol/BSCValidatorSet.json'),
  readByteCode('systemRewardContract', 'out/SystemReward.sol/SystemReward.json'),
  readByteCode('slashContract', 'out/SlashIndicator.sol/SlashIndicator.json'),
  readByteCode('tendermintLightClient', 'out/TendermintLightClient.sol/TendermintLightClient.json'),
  readByteCode('tokenHub', 'out/TokenHub.sol/TokenHub.json'),
  readByteCode('relayerHub', 'out/RelayerHub.sol/RelayerHub.json'),
  readByteCode('relayerIncentivize', 'out/RelayerIncentivize.sol/RelayerIncentivize.json'),
  readByteCode('govHub', 'out/GovHub.sol/GovHub.json'),
  readByteCode('tokenManager', 'out/TokenManager.sol/TokenManager.json'),
  readByteCode('crossChain', 'out/CrossChain.sol/CrossChain.json'),
  readByteCode('staking', 'out/Staking.sol/Staking.json'),
  readByteCode('stakeHub', 'out/StakeHub.sol/StakeHub.json'),
  readByteCode('stakeCredit', 'out/StakeCredit.sol/StakeCredit.json'),
  readByteCode('governor', 'out/BSCGovernor.sol/BSCGovernor.json'),
  readByteCode('govToken', 'out/GovToken.sol/GovToken.json'),
  readByteCode('timelock', 'out/BSCTimelock.sol/BSCTimelock.json'),
  readByteCode('tokenRecoverPortal', 'out/TokenRecoverPortal.sol/TokenRecoverPortal.json'),
]).then((result) => {
  const data = {
    chainId: program.chainId,
    initHolders: init_holders,
    extraData: web3.utils.bytesToHex(validators.extraValidatorBytes),
  };

  if (program.maxwellTime !== undefined && program.maxwellTime !== '') data.maxwellTime = program.maxwellTime;
  if (program.fermiTime !== undefined && program.fermiTime !== '') data.fermiTime = program.fermiTime;
  if (program.osakaTime !== undefined && program.osakaTime !== '') data.osakaTime = program.osakaTime;
  if (program.mendelTime !== undefined && program.mendelTime !== '') data.mendelTime = program.mendelTime;

  result.forEach((r) => {
    data[r.key] = r.compiledData;
  });

  const templateString = fs.readFileSync(program.template).toString();
  const resultString = nunjucks.renderString(templateString, data);
  fs.writeFileSync(program.output, resultString);
});
