use anchor_lang::prelude::*;

declare_id!("Brv1ctepqanoZ77mExP6RRs7b9oJGgFaDj8PAw8PAPPS");

#[program]
pub mod solana_test {
    use super::*;
    
    pub fn say_hello(ctx: Context<SayHello>) -> Result<()> {
        msg!("Hello, Solana!");
        Ok(())
    }
}

#[derive(Accounts)]
pub struct SayHello {}
