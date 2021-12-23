import { createClient, sleep, TonContract } from "@rsquad/ton-utils";
import pkgTokenRoot from "../ton-packages/RootTokenContract.package";
import pkgSmvRoot from "../ton-packages/SmvRoot.package";
import pkgVotingWallet from "../ton-packages/VotingWallet.package";
import pkgSafeMultisigWallet from "../ton-packages/SCMS.package";
import { callThroughMultisig } from "@rsquad/ton-utils/dist/net";
import deploySystem from "./deploy-system";

(async () => {
  let client = createClient();
  let smcSafeMultisigWallet;
  let smcTokenRoot: TonContract;
  let smcSmvRoot;
  let smcVotingWallet;

  smcSafeMultisigWallet = new TonContract({
    client,
    name: "SafeMultisigWallet",
    tonPackage: pkgSafeMultisigWallet,
    address: process.env.MULTISIG_ADDRESS,
    keys: {
      public: process.env.MULTISIG_PUBKEY,
      secret: process.env.MULTISIG_SECRET,
    },
  });

  smcSmvRoot = (await deploySystem()).smcSmvRoot;

  smcTokenRoot = new TonContract({
    client,
    name: "TokenRoot",
    tonPackage: pkgTokenRoot,
    address: process.env.TIP3_ADDRESS,
  });

  const balanceBefore = await smcSafeMultisigWallet.getBalance();

  await callThroughMultisig({
    client,
    smcSafeMultisigWallet,
    abi: pkgSmvRoot.abi,
    functionName: "deployVotingWallet",
    input: {
      addrOwner: smcSafeMultisigWallet.address,
    },
    dest: smcSmvRoot.address,
    value: 2_200_000_000,
  });

  const balanceAfter = await smcSafeMultisigWallet.getBalance();

  console.log({
    balanceBefore,
    balanceAfter,
    diff: ((balanceBefore - balanceAfter) / 10 ** 9).toFixed(3),
  });

  smcVotingWallet = new TonContract({
    client,
    name: "VotingWallet",
    tonPackage: pkgVotingWallet,
    address: (
      await smcSmvRoot.run({
        functionName: "resolveVotingWallet",
        input: {
          addrRoot: smcSmvRoot.address,
          addrOwner: smcSafeMultisigWallet.address,
        },
      })
    ).value.addrVotingWallet,
  });

  console.log("smcVotingWallet deployed: ", smcVotingWallet.address);
  console.log(
    "smcVotingWallet deployed: ",
    await smcVotingWallet.run({ functionName: "_addrTokenWallet" })
  );

  process.exit();
})();
