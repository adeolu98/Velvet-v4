import { deployments, ethers, getNamedAccounts } from "hardhat";
import { Signer } from "ethers";

// test setup
export const setupTest = deployments.createFixture(async (hre) => {
    const { deployer, user, executor, receiver } =
        await getNamedAccounts();
    const { deploy } = hre.deployments;


    await deploy("Token1", {
        from: deployer,
        contract: "TESTERC20",
        args: [
            "Token1",
            "T1"
        ],
        log: true,
    });

    await deploy("Token2", {
        from: deployer,
        contract: "TESTERC20",
        args: [
            "Token2",
            "T2"
        ],
        log: true,
    });

    await deploy("Aggregator", {
        from: deployer,
        contract: "Aggregator",
        log: true,
    });

    await deploy("EnsoAggregatorHelper", {
        from: deployer,
        contract: "EnsoAggregatorHelper",
        log: true
    })

    const ensoHelper = await getContract("EnsoAggregatorHelper", await ethers.getSigner(executor))


    await deploy("EnsoAggregator", {
        from: deployer,
        contract: "EnsoAggregator",
        args: [ensoHelper.target],
        log: true,
    });


    const aggregator = await getContract(
        "Aggregator",
        await ethers.getSigner(executor)
    );



    const ensoAggregator = await getContract(
        "EnsoAggregator",
        await ethers.getSigner(executor)
    );


    await deploy("MetaAggregatorTestSwapContract", {
        from: deployer,
        contract: "MetaAggregatorSwapContract",
        args: [ensoAggregator.target],
        log: true,
    });

    const metaAggregatorTestSwapContract = await getContract(
        "MetaAggregatorTestSwapContract",
        await ethers.getSigner(executor)
    );

    await deploy("MetaAggregatorManager", {
        from: deployer,
        contract: "MetaAggregatorManager",
        args: [metaAggregatorTestSwapContract.target],
        log: true,
    });


    const metaAggregatorTestManager = await getContract(
        "MetaAggregatorManager",
        await ethers.getSigner(executor)
    )

    const token1 = await getContract(
        "Token1",
        await ethers.getSigner(executor)
    );

    const token2 = await getContract(
        "Token2",
        await ethers.getSigner(executor)
    );

    await deploy("NonReentrantTest", {
        from: deployer,
        contract: "NonReentrantTest",
        log: true,
    });

    const nonReentrantTest = await getContract(
        "NonReentrantTest",
        await ethers.getSigner(executor)
    );

    await deploy("ReceiverContract", {
        from: deployer,
        contract: "ReceiverContract",
        log: true,
    });
    const receiverContract = await getContract("ReceiverContract", await ethers.getSigner(executor))


    await deploy("ReceiverRevert", {
        from: deployer,
        contract: "ReceiverRevert",
        log: true,
    });
    const receiverRevert = await getContract("ReceiverRevert", await ethers.getSigner(executor))
    
    const nativeToken = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    const zeroAddress = "0x0000000000000000000000000000000000000000"

    console.log("*******************************test setup completed*******************************")

    return {
        token1,
        token2,
        aggregator,
        ensoAggregator,
        metaAggregatorTestManager,
        metaAggregatorTestSwapContract,
        nativeToken,
        deployer,
        executor,
        user,
        receiver,
        ensoHelper,
        nonReentrantTest,
        receiverContract,
        receiverRevert,
        zeroAddress,
        deploy
    };
});

//Helper function for test
export async function getContract(name: string, signer?: Signer) {
    const c = await deployments.get(name);
    return await ethers.getContractAt(c.abi, c.address, signer);
}
