import BigNumber from "bignumber.js";

export function calculateFee(amount: string, feePercentage: number): { amountAfterFee: string, fee: string } {
    const fee = new BigNumber(amount).multipliedBy(new BigNumber(feePercentage)).dividedBy(100).toFixed(0);
    const amountAfterFee = new BigNumber(amount).minus(fee).toFixed(0);
    return {amountAfterFee, fee};
}

export function divideFee(feeAmount: string, feePercentageReceiver1: number): { feeReceiver1: string, feeReceiver2: string } {
    const feeReceiver1 = new BigNumber(feeAmount).multipliedBy(new BigNumber(feePercentageReceiver1)).dividedBy(100).toFixed(0);
    const feeReceiver2 = new BigNumber(feeAmount).multipliedBy(100 - feePercentageReceiver1).dividedBy(100).toFixed(0);
    return {feeReceiver1, feeReceiver2};    
}

