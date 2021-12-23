export default {
  abi: {
    "ABI version": 2,
    version: "2.2",
    header: ["time", "expire"],
    functions: [
      {
        name: "constructor",
        inputs: [
          { name: "addrAuthor", type: "address" },
          { name: "addrReply", type: "address" },
          { name: "content", type: "string" },
        ],
        outputs: [],
      },
      {
        name: "getPublic",
        inputs: [],
        outputs: [
          { name: "addrProposal", type: "address" },
          { name: "addrAuthor", type: "address" },
          { name: "addrReply", type: "address" },
          { name: "id", type: "uint32" },
          { name: "createdAt", type: "uint32" },
          { name: "content", type: "string" },
        ],
      },
      {
        name: "_addrProposal",
        inputs: [],
        outputs: [{ name: "_addrProposal", type: "address" }],
      },
      {
        name: "_addrAuthor",
        inputs: [],
        outputs: [{ name: "_addrAuthor", type: "address" }],
      },
      {
        name: "_addrReply",
        inputs: [],
        outputs: [{ name: "_addrReply", type: "address" }],
      },
      { name: "_id", inputs: [], outputs: [{ name: "_id", type: "uint32" }] },
      {
        name: "_createdAt",
        inputs: [],
        outputs: [{ name: "_createdAt", type: "uint32" }],
      },
      {
        name: "_content",
        inputs: [],
        outputs: [{ name: "_content", type: "string" }],
      },
    ],
    data: [{ key: 1, name: "_id", type: "uint32" }],
    events: [],
    fields: [
      { name: "_pubkey", type: "uint256" },
      { name: "_timestamp", type: "uint64" },
      { name: "_constructorFlag", type: "bool" },
      { name: "_addrProposal", type: "address" },
      { name: "_addrAuthor", type: "address" },
      { name: "_addrReply", type: "address" },
      { name: "_id", type: "uint32" },
      { name: "_createdAt", type: "uint32" },
      { name: "_content", type: "string" },
    ],
  },
  image:
    "te6ccgECIAEABNEAAgE0AwEBAcACAEPQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAgaK2zUfBAQkiu1TIOMDIMD/4wIgwP7jAvILHAYFHgLg7UTQ10nDAfhmjQhgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE+Gkh2zzTAAGfgQIA1xgg+QFY+EL5EPKo3tM/AfhDIbnytCD4I4ED6KiCCBt3QKC58rT4Y9MfAfgjvPK50x8B2zzyPA0HA1LtRNDXScMB+GYi0NMD+kAw+GmpOADcIccA4wIh1w0f8rwh4wMB2zzyPBsbBwIoIIIQH8KTIbvjAiCCEHTNjv674wITCARQIIIQI4uHprrjAiCCEDeebWm64wIgghBJuYK8uuMCIIIQdM2O/rrjAhIREAkE8jD4Qm7jAPhG8nMhk9TR0N76QNTR0PpA1NH4QYjIz44rbNbMzsnbPCBu8tBkIG7yf9D6QDD4SY0IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABMcF8tBk+EkhxwXy4GT4alj4awH4bPgj+G74b9s88gANHwoVAhjQIIs4rbNYxwWKiuILDAEK103Q2zwMAELXTNCLL0pA1yb0BDHTCTGLL0oY1yYg10rCAZLXTZIwbeICFu1E0NdJwgGOgOMNDhoB/HDtRND0BY0IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABPhqjQhgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE+GuNCGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAT4bHEhgED0Dg8BOpPXCx+RcOL4bXD4boj4b4BA9A7yvdcL//hicPhjHgFQMNHbPPhOIY4cjQRwAAAAAAAAAAAAAAAAMm5gryDIzssfyXD7AN7yABoBTjDR2zz4SyGOG40EcAAAAAAAAAAAAAAAAC3nm1pgyM7OyXD7AN7yABoBTjDR2zz4TCGOG40EcAAAAAAAAAAAAAAAACji4emgyM7OyXD7AN7yABoEUCCCEA8RwKK64wIgghAVqZFAuuMCIIIQHZz67brjAiCCEB/CkyG64wIZGBcUA5Iw+Eby4Ez4Qm7jANHbPCaOLyjQ0wH6QDAxyM+HIM5xzwthXlDIz5J/CkyGzlVAyM5VMMjOyx/LH8zNzc3JcPsAkl8G4jDbPPIAGhYVAFT4T/hO+E34TPhL+Er4Q/hCyMv/yz/Pg85VQMjOVTDIzssfyx/Mzc3J7VQAbo0IYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABF8gcPhKNPhLM/hMMvhO+E0y+E8BTjDR2zz4TyGOG40EcAAAAAAAAAAAAAAAACdnPrtgyM7MyXD7AN7yABoBTjDR2zz4SiGOG40EcAAAAAAAAAAAAAAAACVqZFAgyM7OyXD7AN7yABoBUDDR2zz4TSGOHI0EcAAAAAAAAAAAAAAAACPEcCigyM7LH8lw+wDe8gAaAFjtRNDT/9M/0wAx+kDU0dD6QNTR0PpA0x/TH9TR+G/4bvht+Gz4a/hq+GP4YgAK+Eby4EwCCvSkIPShHh0AFHNvbCAwLjUzLjAAAAAMIPhh7R7Z",
};
