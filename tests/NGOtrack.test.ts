

// import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
// import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Clarinet.test({
//     name: "Ensures NGO registration works",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet1 = accounts.get("wallet_1")!;

//         let block = chain.mineBlock([
//             Tx.contractCall("ngotrack", "register-ngo", [
//                 types.ascii("Test NGO"),
//                 types.ascii("NGO123"),
//                 types.ascii("USA"),
//                 types.uint(1960),
//                 types.ascii("www.testngo.org"),
//                 types.ascii("contact@testngo.org")
//             ], wallet1.address)
//         ]);
//         assertEquals(block.receipts.length, 1);
//         assertEquals(block.height, 2);
//         assertEquals(block.receipts[0].result.expectOk(), "u1");
//     },
// });

// Clarinet.test({
//     name: "Ensures verification works only for owner",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         const deployer = accounts.get("deployer")!;
//         const wallet1 = accounts.get("wallet_1")!;

//         let block = chain.mineBlock([
//             Tx.contractCall("ngotrack", "verify-ngo", [types.uint(1)], deployer.address),
//             Tx.contractCall("ngotrack", "verify-ngo", [types.uint(1)], wallet1.address)
//         ]);
        
//         assertEquals(block.receipts[0].result.expectOk(), true);
//         assertEquals(block.receipts[1].result.expectErr(), "u100");
//     },
// });
