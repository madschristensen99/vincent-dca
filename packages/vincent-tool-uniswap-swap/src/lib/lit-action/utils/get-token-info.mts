/**
 * Retrieves token information (decimals, balance, and parsed amount).
 * @param {JsonRpcProvider} provider - The Ethereum provider.
 * @returns {Promise<{ tokenIn: { decimals: number, balance: any, amount: any, contract: any }, tokenOut: { decimals: number, balance: any, contract: any } }>} Token information.
 */
export async function getTokenInfo(
  provider: any,
  tokenIn: string,
  amountIn: any,
  tokenOut: string,
  pkp: any
) {
  console.log('Gathering token info...');
  ethers.utils.getAddress(tokenIn);
  ethers.utils.getAddress(tokenOut);

  // Check code
  const codeIn = await provider.getCode(litActionParams.tokenIn);
  if (codeIn === '0x') {
    throw new Error(`No contract found at ${litActionParams.tokenIn}`);
  }
  const codeOut = await provider.getCode(litActionParams.tokenOut);
  if (codeOut === '0x') {
    throw new Error(`No contract found at ${litActionParams.tokenOut}`);
  }

  const tokenInterface = new ethers.utils.Interface([
    'function decimals() view returns (uint8)',
    'function balanceOf(address) view returns (uint256)',
    'function approve(address,uint256) external returns (bool)',
  ]);
  const tokenInContract = new ethers.Contract(
    litActionParams.tokenIn,
    tokenInterface,
    provider
  );
  const tokenOutContract = new ethers.Contract(
    litActionParams.tokenOut,
    tokenInterface,
    provider
  );

  // Parallel calls
  const [decimalsIn, decimalsOut] = await Promise.all([
    tokenInContract.decimals(),
    tokenOutContract.decimals(),
  ]);
  console.log('Token decimals:', decimalsIn, decimalsOut);

  const [balanceIn, balanceOut] = await Promise.all([
    tokenInContract.balanceOf(pkp.ethAddress),
    tokenOutContract.balanceOf(pkp.ethAddress),
  ]);
  console.log(
    'Token balances (in/out):',
    balanceIn.toString(),
    balanceOut.toString()
  );

  const _amountIn = ethers.utils.parseUnits(amountIn, decimalsIn);
  if (_amountIn.gt(balanceIn)) {
    throw new Error(
      `amountIn: ${_amountIn.toString()} is greater than tokenIn balance: ${balanceIn.toString()}`
    );
  }
  return {
    tokenIn: {
      decimals: decimalsIn,
      balance: balanceIn,
      amount: _amountIn,
      contract: tokenInContract,
    },
    tokenOut: {
      decimals: decimalsOut,
      balance: balanceOut,
      contract: tokenOutContract,
    },
  };
}
