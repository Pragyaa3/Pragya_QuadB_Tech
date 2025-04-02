use anchor_lang::prelude::*;

declare_id!("6cpgRW1r25unm3xx4sQzojvk6jEdW83AdbsCJAABzQY9");

#[program]
pub mod user_data_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, name: String, age: u8) -> Result<()> {
        let user_account = &mut ctx.accounts.user_account;
        user_account.name = name;
        user_account.age = age;
        user_account.authority = *ctx.accounts.user.key;
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = user, space = 8 + 4 + 32 + 40)]
    pub user_account: Account<'info, UserData>,
    #[account(mut)]
    pub user: Signer<'info>,
    #[account(address = anchor_lang::system_program::ID)]
    pub system_program: Program<'info, System>,}

#[account]
pub struct UserData {
    pub name: String,
    pub age: u8,
    pub authority: Pubkey,
}
