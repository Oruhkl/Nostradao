import React from "react";
import { motion } from "framer-motion";
import { generateRandomBets } from "../utils/bets";
import { PredictionMarkets } from "../components/PredictionMarkets";

export const MarketsPage: React.FC = () => {
    const randomPredictionMarketsBets = generateRandomBets(10);

    return (
        <motion.div className="flex flex-col space-y-5 justify-start items-center">
            <motion.div className="flex flex-col justify-start space-y-4 py-4 w-full px-6">
                <p className="text-xl font-bold text-white mr-auto">
                    Prediction Markets
                </p>
                <div className="grid grid-cols-auto-fit w-full gap-4">
                    {randomPredictionMarketsBets.map((bet, index) => (
                        <PredictionMarkets key={index} {...bet} />
                    ))}
                </div>
            </motion.div>
        </motion.div>
    );
};
