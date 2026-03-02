import numpy as np
import tkinter as tk
from tkinter import ttk, messagebox
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
from scipy.integrate import solve_ivp
from scipy.optimize import root_scalar
import math

class SimuladorBalistica:
    def __init__(self, root):
        self.root = root
        self.root.title("Simulador de Balística - FNC232 (Modernizado)")
        self.root.geometry("1100x600")
        
        # Tabelas de Mach vs Drag Coefficient (CD) - Mantidas do original (Nearest Neighbor)
        self.mach_table = np.array([0.0, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0])
        self.cd_table = np.array([1.6, 1.8, 2.1, 4.8, 5.8, 5.4, 4.8, 4.2, 3.9])

        self.setup_ui()

    def get_cd(self, v_mag, v_som):
        """Calcula o Coeficiente de Arrasto (CD) baseado no número de Mach por vizinho mais próximo, como no Pascal."""
        mach = v_mag / v_som
        idx = np.abs(self.mach_table - mach).argmin()
        return self.cd_table[idx]

    def equacoes_movimento(self, t, state, massa, diametro, ro, v_som, gravidade):
        """Derivadas de estado para o integrador (x, y, vx, vy)"""
        x, y, vx, vy = state
        v_mag = np.hypot(vx, vy)
        
        if v_mag == 0:
            return [vx, vy, 0, -gravidade]

        cd = self.get_cd(v_mag, v_som)
        
        # Fator de arrasto = (Cd * pi * d^2 * rho) / 8m  (Simplificado da área pi*d^2/4)
        fator_arrasto = (cd * np.pi * diametro**2 * ro) / (8 * massa)
        
        ax = -fator_arrasto * v_mag * vx
        ay = -gravidade - fator_arrasto * v_mag * vy
        
        return [vx, vy, ax, ay]

    def simular_trajetoria(self, angulo_rad, v0, massa, diametro, ro, v_som, gravidade):
        """Calcula a trajetória completa até atingir o solo (y=0)"""
        vx0 = v0 * np.cos(angulo_rad)
        vy0 = v0 * np.sin(angulo_rad)
        state0 = [0.0, 0.0, vx0, vy0]
        
        # Evento para parar a integração quando y <= 0
        def atingiu_solo(t, state, *args): return state[1]
        atingiu_solo.terminal = True
        atingiu_solo.direction = -1

        # Tempo máximo estimado longo o suficiente para o projétil cair
        t_max = 1000.0 
        
        sol = solve_ivp(
            fun=self.equacoes_movimento,
            t_span=(0, t_max),
            y0=state0,
            args=(massa, diametro, ro, v_som, gravidade),
            events=atingiu_solo,
            dense_output=True,
            max_step=0.1
        )
        return sol

    def rad_para_graus_min_seg(self, angulo_rad):
        """Converte radianos para string de Graus, Minutos e Segundos."""
        graus_dec = np.degrees(angulo_rad)
        g = int(graus_dec)
        minutos_dec = (graus_dec - g) * 60
        m = int(minutos_dec)
        s = (minutos_dec - m) * 60
        return f"{g}° {m}' {s:.1f}''"

    def calcular(self):
        try:
            # Captura dados de entrada
            massa = float(self.ent_massa.get())
            diametro = float(self.ent_diametro.get())
            v0 = float(self.ent_v0.get())
            alcance_alvo = float(self.ent_alcance.get())
            epslon = float(self.ent_epslon.get())
            ro = float(self.ent_ro.get())
            v_som = float(self.ent_vsom.get())
            gravidade = float(self.ent_grav.get())
        except ValueError:
            messagebox.showerror("Erro de Entrada", "Por favor, insira valores numéricos válidos.")
            return

        # Limpa o gráfico
        self.ax.clear()
        self.ax.set_title('Trajetórias do Projétil')
        self.ax.set_xlabel('Alcance Horizontal (m)')
        self.ax.set_ylabel('Altura (m)')
        self.ax.grid(True)

        self.txt_resultados.delete('1.0', tk.END)
        self.txt_resultados.insert(tk.END, "Buscando ângulos...\n\n")
        self.root.update()

        # Função de erro (diferença entre o alcance do disparo e o alvo)
        def erro_alcance(angulo):
            sol = self.simular_trajetoria(angulo, v0, massa, diametro, ro, v_som, gravidade)
            x_final = sol.y[0][-1]
            return x_final - alcance_alvo

        # Encontrando o ângulo de alcance máximo para dividir a busca
        angulos_teste = np.linspace(0.01, np.pi/2 - 0.01, 45)
        alcances = [self.simular_trajetoria(ang, v0, massa, diametro, ro, v_som, gravidade).y[0][-1] for ang in angulos_teste]
        alcance_maximo = max(alcances)
        angulo_max = angulos_teste[np.argmax(alcances)]

        if alcance_maximo < alcance_alvo - epslon:
            self.txt_resultados.insert(tk.END, "O alcance não pode ser atingido com a velocidade inicial fornecida!\n")
            self.canvas.draw()
            return

        angulos_sucesso = []
        cores = ['blue', 'red']
        nomes = ['Tiro por Baixo (Teta 2)', 'Tiro por Cima (Teta 1)']

        # Busca por baixo (entre 0 e o ângulo de alcance máximo)
        try:
            res_baixo = root_scalar(erro_alcance, bracket=[0.001, angulo_max], xtol=1e-5)
            if res_baixo.converged:
                angulos_sucesso.append((res_baixo.root, nomes[0], cores[0]))
        except ValueError:
            pass

        # Busca por cima (entre o ângulo de alcance máximo e 90 graus)
        try:
            res_cima = root_scalar(erro_alcance, bracket=[angulo_max, np.pi/2 - 0.001], xtol=1e-5)
            if res_cima.converged:
                angulos_sucesso.append((res_cima.root, nomes[1], cores[1]))
        except ValueError:
            pass

        if not angulos_sucesso:
            self.txt_resultados.insert(tk.END, "Não foi possível estabilizar uma trajetória para o alvo.\n")
            return

        for angulo, nome, cor in angulos_sucesso:
            sol = self.simular_trajetoria(angulo, v0, massa, diametro, ro, v_som, gravidade)
            x_traj = sol.y[0]
            y_traj = sol.y[1]
            tempo_voo = sol.t[-1]
            v_impacto = np.hypot(sol.y[2][-1], sol.y[3][-1])

            # Calcula erro com +/- 10 minutos (aprox 0.0029 radianos) de variação (do original)
            erro_10min_rad = np.radians(10/60)
            alcance_mais = self.simular_trajetoria(angulo + erro_10min_rad, v0, massa, diametro, ro, v_som, gravidade).y[0][-1]
            alcance_menos = self.simular_trajetoria(angulo - erro_10min_rad, v0, massa, diametro, ro, v_som, gravidade).y[0][-1]
            erro_sensibilidade = max(abs(alcance_mais - alcance_alvo), abs(alcance_menos - alcance_alvo))

            self.ax.plot(x_traj, y_traj, label=f"{nome} - {self.rad_para_graus_min_seg(angulo)}", color=cor)
            
            # Exibe resultados
            res_texto = (
                f"--- {nome} ---\n"
                f"Ângulo: {self.rad_para_graus_min_seg(angulo)}\n"
                f"Tempo de Voo: {tempo_voo:.4f} s\n"
                f"Velocidade de Impacto: {v_impacto:.4f} m/s\n"
                f"Erro Sensibilidade (+/- 10 min): {erro_sensibilidade:.4f} m\n\n"
            )
            self.txt_resultados.insert(tk.END, res_texto)

        self.ax.legend()
        self.canvas.draw()

    def setup_ui(self):
        # Frame de Entradas
        frame_in = tk.Frame(self.root, width=300)
        frame_in.pack(side=tk.LEFT, fill=tk.Y, padx=10, pady=10)

        tk.Label(frame_in, text="Massa do Projétil (kg):").pack(anchor="w")
        self.ent_massa = tk.Entry(frame_in)
        self.ent_massa.pack(fill=tk.X, pady=2)
        self.ent_massa.insert(0, "43.5") # Valor padrão de exemplo

        tk.Label(frame_in, text="Diâmetro (m):").pack(anchor="w")
        self.ent_diametro = tk.Entry(frame_in)
        self.ent_diametro.pack(fill=tk.X, pady=2)
        self.ent_diametro.insert(0, "0.155")

        tk.Label(frame_in, text="Velocidade Inicial (m/s):").pack(anchor="w")
        self.ent_v0 = tk.Entry(frame_in)
        self.ent_v0.pack(fill=tk.X, pady=2)
        self.ent_v0.insert(0, "800.0")

        tk.Label(frame_in, text="Alcance Alvo (m):").pack(anchor="w")
        self.ent_alcance = tk.Entry(frame_in)
        self.ent_alcance.pack(fill=tk.X, pady=2)
        self.ent_alcance.insert(0, "15000.0")

        tk.Label(frame_in, text="Erro Tolerado - Epsilon (m):").pack(anchor="w")
        self.ent_epslon = tk.Entry(frame_in)
        self.ent_epslon.pack(fill=tk.X, pady=2)
        self.ent_epslon.insert(0, "1.0")

        tk.Label(frame_in, text="Densidade do Ar (kg/m3):").pack(anchor="w")
        self.ent_ro = tk.Entry(frame_in)
        self.ent_ro.pack(fill=tk.X, pady=2)
        self.ent_ro.insert(0, "1.225")

        tk.Label(frame_in, text="Velocidade do Som (m/s):").pack(anchor="w")
        self.ent_vsom = tk.Entry(frame_in)
        self.ent_vsom.pack(fill=tk.X, pady=2)
        self.ent_vsom.insert(0, "340.0")

        tk.Label(frame_in, text="Gravidade (m/s2):").pack(anchor="w")
        self.ent_grav = tk.Entry(frame_in)
        self.ent_grav.pack(fill=tk.X, pady=2)
        self.ent_grav.insert(0, "9.81")

        btn_calcular = tk.Button(frame_in, text="Simular Trajetórias", command=self.calcular, bg="lightblue")
        btn_calcular.pack(fill=tk.X, pady=15)

        tk.Label(frame_in, text="Resultados:").pack(anchor="w")
        self.txt_resultados = tk.Text(frame_in, height=12, width=35)
        self.txt_resultados.pack(fill=tk.BOTH, expand=True)

        # Frame de Gráficos (Direita)
        frame_out = tk.Frame(self.root)
        frame_out.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

        self.fig, self.ax = plt.subplots()
        self.ax.set_title('Trajetórias do Projétil')
        self.ax.set_xlabel('Alcance Horizontal (m)')
        self.ax.set_ylabel('Altura (m)')
        self.ax.grid(True)
        
        self.canvas = FigureCanvasTkAgg(self.fig, master=frame_out)
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)


if __name__ == "__main__":
    root = tk.Tk()
    app = SimuladorBalistica(root)
    root.mainloop()