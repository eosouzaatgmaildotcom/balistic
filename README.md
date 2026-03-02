# balistic
A modernized Python ballistics simulator that calculates realistic projectile trajectories with aerodynamic drag and determines the exact launch angles required to hit a specific target.

# Ballistics Simulator: From 90s Turbo Pascal to Modern Python 🚀



This repository contains the modernized version of a ballistics simulator with aerodynamic drag. The project calculates the trajectory of a projectile, considering air resistance based on the Mach number, and accurately finds the exact firing angles (high and low trajectories) required to hit a target at a specific distance.

## 📜 Project History

This code carries a rich academic heritage. The original version was developed in the 1990s in Turbo Pascal as the final project for the **FNC 232 - Scientific Programming Languages and Efficient Programming Techniques** course, under the guidance of Professor Maria Lucia. 

The original authors of the classic version are **Aurea Garcia** and **Evandro Oliveira Souza Neto**.

The current version is a modernization that preserves the flawless physical logic of the original project but replaces the manual numerical calculations and the old graphical interface libraries (`crt`, `graph`) with the modern scientific ecosystem of the Python language.

## ✨ Features

* **Integrated Graphical Interface:** Uses `tkinter` for data entry and `matplotlib` for interactive trajectory visualization.
* **Realistic Physics:** Accounts for dynamic air resistance (drag) using a Drag Coefficient (CD) vs. Mach Number table (interpolated via the nearest neighbor method, true to the original).
* **Advanced ODE Solver:** Integrates the differential equations of motion using the `scipy.integrate.solve_ivp` library, replacing the manual implementation of the 4th-order Runge-Kutta method (RK4).
* **Root Finding for Angles:** Uses `scipy.optimize.root_scalar` to accurately find the two possible launch angles that hit the target (Theta 1 and Theta 2), replacing the old manual recursive search.
* **Sensitivity Analysis:** Calculates and displays the range error (in meters) caused by a +/- 10 arcminute variation in the firing angle.

## 🛠️ Technologies Used

* **Python 3.x**
* **NumPy:** For efficient vector and mathematical calculations.
* **SciPy:** For numerical integration (adaptive RK45/DOP853) and root-finding algorithms.
* **Matplotlib:** For plotting the projectile's flight profile.
* **Tkinter:** For building the Graphical User Interface (GUI).

## 🚀 How to Install and Run

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YOUR-USERNAME/ballistics-simulator-fnc232.git](https://github.com/YOUR-USERNAME/ballistics-simulator-fnc232.git)
   cd ballistics-simulator-fnc232

2. Create a virtual environment (Optional, but recommended):
python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/Mac:
source venv/bin/activate

3. Install dependencies:
pip install numpy scipy matplotlib

4. Run the simulator:
python balistica_moderna.py

## 🎯 Interesting Simulation Scenarios
To fully experience the physics engine of this simulator, try entering the following parameter combinations in the GUI:

1. Standard Heavy Artillery (155mm Howitzer)

This is the default scenario. It shows the classic two-angle solution (high and low) for a heavy projectile.

Mass: 43.5 kg
Diameter: 0.155 m
Initial Velocity (V0): 800 m/s
Target Range: 15000 m
Air Density (Rho): 1.225 kg/m³

2. The "Impossible" Shot (Out of Range)

Test the algorithm's error handling by trying to hit a target beyond the physical reach of the gun due to air drag.

Target Range: 35000 m

Observation: The console/UI will inform you that the target cannot be reached with the given initial velocity.

3. Firing in a Vacuum (No Air Resistance)

See how far the projectile goes when drag is removed. The trajectory becomes a perfect mathematical parabola.

Air Density (Rho): 0.001 kg/m³ (near vacuum)
Target Range: 35000 m

Observation: Notice how the maximum range increases massively compared to the standard scenario, and the high/low trajectories become perfectly symmetrical.

4. Small Caliber Rifle (7.62mm Bullet)

Lighter projectiles lose velocity much faster due to their low mass-to-drag ratio.

Mass: 0.009 kg (9 grams)
Diameter: 0.00762 m
Initial Velocity (V0): 850 m/s
Target Range: 1200 m

Observation: The impact velocity will be drastically lower than the launch velocity, showcasing the immense effect of drag on lightweight objects.

## 🧠 Architecture: Pascal vs. Python
For legacy code enthusiasts, here are the main architectural transitions:

Feature	Original Version (Turbo Pascal)	Modern Version (Python)
User Interface	uses crt, graph; (Text mode + BGI graphics)	tkinter integrated with matplotlib
Numerical Integration	Manually partitioned RK4	scipy.integrate.solve_ivp (RK45/DOP853)
Angle Search	Custom recursive function achangulo	scipy.optimize.root_scalar (Brent's method)
Data Output	Screen wipe with Cleardevice + PutPixel	Interactive vector graphic with zoom and export.

## 🤝 Contributing
Feel free to open Issues to report bugs or suggest improvements via Pull Requests. Ideas for future implementations include:

Adding air density variation with altitude (Standard Atmosphere model).

Adding the Coriolis effect for extremely long-range calculations.

Exporting trajectory data to .csv.

## 📄 License
This project is open-source and available under the MIT License.
