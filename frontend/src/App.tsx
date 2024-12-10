import { useState } from "react";
import { Route, Routes } from "react-router-dom";
import "./App.css";
import { HomePage } from "./pages/HomePage";
import { AnimatePresence } from "framer-motion";
import Sidebar from "./components/SideBar";
import Navbar from "./components/NavBar";
import { MarketsPage } from "./pages/MarketsPage";
import { MyBetsPage } from "./pages/MyBetsPage";
import { CreatePage } from "./pages/CreatePage";

function App() {
    const [isSidebarOpen, setIsSidebarOpen] = useState<boolean>(false);

    const toggleMobileMenu = (): void => {
        setIsSidebarOpen(!isSidebarOpen);
    };

    return (
        <div className="w-[100vw] bg-black">
            <AnimatePresence>
                <Sidebar
                    isOpen={isSidebarOpen}
                    onClose={() => setIsSidebarOpen(false)}
                />
            </AnimatePresence>

            <Navbar onMobileMenuToggle={toggleMobileMenu} />
            <div className="min-h-screen flex flex-col">
                <Routes>
                    <Route path="/" element={<HomePage />} />
                    <Route path="/markets" element={<MarketsPage />} />
                    <Route path="/bets" element={<MyBetsPage />} />
                    <Route path="/create" element={<CreatePage />} />
                </Routes>
            </div>
        </div>
    );
}

export default App;
