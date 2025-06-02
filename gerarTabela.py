import matplotlib.pyplot as plt
import numpy as np

# Dados
labels = ['1','2','3','4','5']
counts_no_index = [3.29, 3.28, 14.39, 9.18, 10.56]
counts_with_index = [3.06, 2.83, 13.29, 7.43, 10.13]

x = np.arange(len(labels))  # posição dos grupos
width = 0.35  # largura das barras

fig, ax = plt.subplots(figsize=(10, 6))

# Barras
bars1 = ax.bar(x - width/2, counts_no_index, width, label='Sem índice', color='tab:red')
bars2 = ax.bar(x + width/2, counts_with_index, width, label='Com índice', color='tab:green')

# Rótulos e título
ax.set_ylabel('Tempo médio (em ms)')
ax.set_xlabel('Consultas')
ax.set_title('Consultas com e sem índices')
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.legend(title='Tipo de consulta')

# Rótulos nas barras
ax.bar_label(bars1, padding=3)
ax.bar_label(bars2, padding=3)

# Layout ajustado
plt.tight_layout()
plt.show()
