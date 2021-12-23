import { createClient, TonContract } from "@rsquad/ton-utils";
import pkgTokenRoot from "../ton-packages/RootTokenContract.package";
import pkgTONTokenWallet from "../ton-packages/TONTokenWallet.package";
import pkgSafeMultisigWallet from "../ton-packages/SCMS.package";
import {
  callThroughMultisig,
  sendThroughMultisig,
} from "@rsquad/ton-utils/dist/net";
import { utf8ToHex } from "@rsquad/ton-utils/dist/convert";

(async () => {
  try {
    let client = createClient();
    let keys = await client.crypto.generate_random_sign_keys();
    let smcSafeMultisigWallet;
    let smcTokenRoot: TonContract;

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

    smcTokenRoot = new TonContract({
      client,
      name: "TokenRoot",
      tonPackage: pkgTokenRoot,
      keys,
    });

    const nonce = new Date().getSeconds();
    const tokenRootInitialData = {
      _randomNonce: nonce,
      name: utf8ToHex("SMV DAO Token"),
      symbol: utf8ToHex("SDAO"),
      decimals: 0,
      wallet_code: (
        await client.boc.get_code_from_tvc({
          tvc: pkgTONTokenWallet.image,
        })
      ).code,
    };

    await smcTokenRoot.calcAddress({ initialData: tokenRootInitialData });

    await sendThroughMultisig({
      smcSafeMultisigWallet,
      dest: smcTokenRoot.address,
      value: 5_000_000_000,
    });

    await smcTokenRoot.deploy({
      input: {
        root_public_key_: 0,
        root_owner_address_: smcSafeMultisigWallet.address,
      },
      initialData: tokenRootInitialData,
    });

    console.log("TokenRoot deployed: ", smcTokenRoot.address);

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgTokenRoot.abi,
      functionName: "deployWallet",
      input: {
        tokens: 1_000_000,
        deploy_grams: 500_000_000,
        wallet_public_key_: 0,
        owner_address_: process.env.MULTISIG_ADDRESS,
        gas_back_address: process.env.MULTISIG_ADDRESS,
      },
      dest: smcTokenRoot.address,
      value: 1_000_000_000,
    });

    console.log(
      "TokenWallet deployed: ",
      (
        await smcTokenRoot.run({
          functionName: "getWalletAddress",
          input: {
            answerId: 0,
            wallet_public_key_: 0,
            owner_address_: smcSafeMultisigWallet.address,
          },
        })
      ).value.value0
    );

    return { smcTokenRoot };
  } catch (err) {
    console.log(err);
  }
})();
