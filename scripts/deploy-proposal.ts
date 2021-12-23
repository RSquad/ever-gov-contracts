import { createClient, sleep, TonContract } from "@rsquad/ton-utils";
import pkgTokenRoot from "../ton-packages/RootTokenContract.package";
import pkgSmvRoot from "../ton-packages/SmvRoot.package";
import pkgSafeMultisigWallet from "../ton-packages/SCMS.package";
import { callThroughMultisig } from "@rsquad/ton-utils/dist/net";
import deploySystem from "./deploy-system";
import { EMPTY_ADDRESS, EMPTY_CODE } from "@rsquad/ton-utils/dist/constants";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";

(async () => {
  let client = createClient();
  let smcSafeMultisigWallet;
  let smcTokenRoot: TonContract;
  let smcSmvRoot;

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
    functionName: "deployProposal",
    input: {
      addrClient: EMPTY_ADDRESS,
      title: utf8ToHex("title"),
      description: utf8ToHex("description"),
      payload: EMPTY_CODE,
    },
    dest: smcSmvRoot.address,
    value: 1_200_000_000,
  });

  const balanceAfter = await smcSafeMultisigWallet.getBalance();

  console.log({
    balanceBefore,
    balanceAfter,
    diff: ((balanceBefore - balanceAfter) / 10 ** 9).toFixed(3),
  });

  process.exit();
})();
