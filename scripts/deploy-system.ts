import { createClient, sleep, TonContract } from "@rsquad/ton-utils";
import pkgProposal from "../ton-packages/Proposal.package";
import pkgVotingWallet from "../ton-packages/VotingWallet.package";
import pkgTokenRoot from "../ton-packages/RootTokenContract.package";
import pkgComment from "../ton-packages/Comment.package";
import pkgSmvRootStore from "../ton-packages/SmvRootStore.package";
import pkgSmvRoot from "../ton-packages/SmvRoot.package";
import pkgSafeMultisigWallet from "../ton-packages/SCMS.package";
import { sendThroughMultisig } from "@rsquad/ton-utils/dist/net";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";

const f = async () => {
  let client = createClient();
  let keys = await client.crypto.generate_random_sign_keys();
  let smcSafeMultisigWallet;
  let smcSmvRoot;
  let smcTokenRoot;
  let smcSmvRootStore;

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

  smcSmvRoot = new TonContract({
    client,
    name: "SmvRoot",
    tonPackage: pkgSmvRoot,
    keys,
  });
  await smcSmvRoot.calcAddress();

  smcTokenRoot = new TonContract({
    client,
    name: "TokenRoot",
    tonPackage: pkgTokenRoot,
    address: process.env.TIP3_ADDRESS,
  });

  smcSmvRootStore = new TonContract({
    client,
    name: "SmvRootStore",
    tonPackage: pkgSmvRootStore,
    keys,
  });
  await smcSmvRootStore.calcAddress();

  await sendThroughMultisig({
    smcSafeMultisigWallet,
    dest: smcSmvRootStore.address,
    value: 1_000_000_000,
  });
  await smcSmvRootStore.deploy();

  await smcSmvRootStore.call({
    functionName: "setVotingWalletCode",
    input: {
      code: (
        await client.boc.get_code_from_tvc({
          tvc: pkgVotingWallet.image,
        })
      ).code,
    },
  });
  await smcSmvRootStore.call({
    functionName: "setProposalCode",
    input: {
      code: (
        await client.boc.get_code_from_tvc({
          tvc: pkgProposal.image,
        })
      ).code,
    },
  });
  await smcSmvRootStore.call({
    functionName: "setCommentCode",
    input: {
      code: (
        await client.boc.get_code_from_tvc({
          tvc: pkgComment.image,
        })
      ).code,
    },
  });

  await sendThroughMultisig({
    smcSafeMultisigWallet,
    dest: smcSmvRoot.address,
    value: 1_000_000_000,
  });

  await smcSmvRoot.deploy({
    input: {
      addrSmvStore: smcSmvRootStore.address,
      addrTokenRoot: smcTokenRoot.address,
      title: utf8ToHex("Test Evercale Governance 2"),
    },
  });

  console.log({
    smcSmvRoot: smcSmvRoot.address,
  });

  return { smcSmvRoot };
};

f();

export default f;
